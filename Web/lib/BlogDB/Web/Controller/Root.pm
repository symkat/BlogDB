package BlogDB::Web::Controller::Root;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Try::Tiny;
use Data::UUID;

sub get_homepage ($c) {
    $c->set_template( 'index' );

    # Find blogs by tag.
    if ( $c->param('tag') ) {
        push @{$c->stash->{entries}}, $c->db->resultset('BlogEntry')->recent_entries({
            filter_adult => ! $c->stash->{can_view_adult},
            has_tag      => $c->param('tag'),
        });

        my $tag = $c->db->resultset('Tag')->search({ name => $c->param('tag') })->first;
        if ( $tag ) {
            push @{$c->stash->{blogs}}, map { $_->blog }
                $tag->search_related('blog_tag_maps')->all;
        }
    }

    # Create session cookie via query param on homepage.
    if ( defined $c->param( 'cva_setting') ) {
        $c->session->{cva_setting} = $c->param('cva_setting');
    } 

    my $is_user_feed = 0;
    if ( $c->param('view') and $c->param('view') eq 'feed' ) {
        $is_user_feed = 1;
    }

    my $page_number = $c->stash->{page}{number} = $c->param('page') || 1;
    $c->stash->{page}{has_prev} = 1 if $page_number >= 2;
    $c->stash->{page}{prev} = $page_number - 1;
    $c->stash->{page}{next} = $page_number + 1;
    
    if ( ! $c->stash->{entries} ) { 
        my $recent_entries = $c->db->resultset('BlogEntry')->recent_entries({
            filter_adult       => ! $c->stash->{can_view_adult},
            rows_per_page      => 25,

            ( $page_number
                ? ( page_number => $page_number )
                : ()
            ),

            # Should we only show the user's followed things?
            ( $is_user_feed 
                ? ( limit_to_person_id => $c->stash->{person}->id )
                : ( )
            ),

        });
        push @{$c->stash->{entries}}, @{$recent_entries->{results}};
        $c->stash->{page}{has_next} = $recent_entries->{has_next_page};
    }
    
    push @{$c->stash->{tags_a}},  grep  { $_->id % 2 == 1 } $c->db->resultset('Tag')->search({
        ( ! $c->stash->{can_view_adult} ? ( is_adult => 0 ) : () ),
    })->all;

    push @{$c->stash->{tags_b}},  grep  { $_->id % 2 == 0 } $c->db->resultset('Tag')->search({
        ( ! $c->stash->{can_view_adult} ? ( is_adult => 0 ) : () ),
    })->all;

}

sub get_register ($c) {
    $c->set_template( 'register' );

}

sub post_register ($c) {
    $c->set_template( 'register' );

    my $username = $c->stash->{form_username} = $c->param('username');
    my $email    = $c->stash->{form_email}    = $c->param('email');
    my $password = $c->stash->{form_password} = $c->param('password');
    my $confirm  = $c->stash->{form_confirm}  = $c->param('confirm');

    # Error Checking - We have all of the information.
    push @{$c->stash->{errors}}, "Username is required."         unless $username;
    push @{$c->stash->{errors}}, "Email address is required."    unless $email;
    push @{$c->stash->{errors}}, "Password is required."         unless $password;
    push @{$c->stash->{errors}}, "Confirm password is required." unless $password;

    # Error Checking - Username conforms to expectations:
    push @{$c->stash->{errors}}, "Usernames must start with a letter and then may contain letters, numbers, underscores and dashes."
        unless $username =~ /^[a-zA-Z][a-zA-Z0-9_-]+$/;

    return 0 if $c->stash->{errors}; # Drop out of processing the registration if there are any errors.

    # Error Checking - No user exists with this username or email address, password is valid.
    my $is_user_exist  = $c->db->resultset('Person')->find( { username => $username } );
    my $is_email_exist = $c->db->resultset('Person')->find( { email    => $email    } );

    push @{$c->stash->{errors}}, "Password & Confirmation must match."       unless $password eq $confirm;
    push @{$c->stash->{errors}}, "Password must be at least 7 chars."        unless 7 < length($password);
    push @{$c->stash->{errors}}, "This username is already in use."          unless not $is_user_exist;
    push @{$c->stash->{errors}}, "This email address is already registered." unless not $is_email_exist;

    return 0 if $c->stash->{errors}; # Drop out of processing the registration if there are any errors.

    # Alright, we are clear to create the account now.

    my $person = try {
        $c->db->storage->schema->txn_do( sub {
            my $person = $c->db->resultset('Person')->create({
                email    => $email,
                username => $username,
            });
            $person->new_related( 'auth_password', {} )->set_password($password);
            return $person;
        });
    } catch {
        push @{$c->stash->{errors}}, "The account could not be created: $_";
    };

    return 0 if $c->stash->{errors}; # Drop out of processing the registration if there are any errors.

    # We have created a user account for this person
    $c->session->{uid} = $person->id;

    $c->redirect_to( $c->url_for( 'homepage' ) );
}

sub get_forgot ($c) {
    $c->set_template( 'forgot' );
}

sub post_forgot ($c) {
    $c->set_template( 'forgot' );
    
    my $username = $c->stash->{form_username} = $c->param('username');

    # Find the user -- if they have an @, assume it's an email addresss.
    my $person = $c->db->resultset('Person')->find( index($username, '@') == -1
        ? { username => $username }
        : { email    => $username }
    );

    push @{$c->stash->{errors}}, "No such username or email address."
        unless $person;

    return 0 if $c->stash->{errors}; # Drop out of processing if there are errors.

    my $reset_token = $person->create_related( 'password_tokens', {
        token => Data::UUID->new->create_str,
    });

    # TODO
    # This is the part where we email $person->email with $c->url_for( 'reset', { token => $reset_token->token } );

    $c->stash->{success} = 1;
}

sub get_reset ($c) {
    $c->set_template( 'reset' );

    $c->stash->{form_token} = $c->param('token');

}

sub post_reset ($c) {
    $c->set_template( 'reset' );
    
    my $form_token = $c->stash->{form_token}    = $c->param('reset_token');
    my $password   = $c->stash->{form_password} = $c->param('password');
    my $confirm    = $c->stash->{form_confirm}  = $c->param('confirm');

    # Error Checking - We have all of the information.
    push @{$c->stash->{errors}}, "Password is required."               unless $password;
    push @{$c->stash->{errors}}, "Confirm password is required."       unless $password;
    push @{$c->stash->{errors}}, "Password & Confirmation must match." unless $password eq $confirm;
    push @{$c->stash->{errors}}, "Password must be at least 7 chars."  unless 7 < length($password);

    return 0 if $c->stash->{errors}; # Drop out of processing, there are errors..

    my $token = $c->db->resultset('PasswordToken')->search({
        token       => $form_token,
        is_redeemed => 0,
    })->first;

    push @{$c->stash->{errors}}, "Invalid token"  unless $token;;
    return 0 if $c->stash->{errors}; # Drop out of processing, there are errors..

    my $person = try {
        $c->db->storage->schema->txn_do( sub {
            # Update the user's password.
            $token->person->auth_password->update_password( $password );
            
            # Mark the token used.
            $token->is_redeemed( 1 );
            $token->update;

            return $token->person;
        });
    } catch {
        push @{$c->stash->{errors}}, "The password could not be reset: $_";
    };

    return 0 if $c->stash->{errors}; # Drop out of processing the registration if there are any errors.

    $c->stash->{success} = 1;
}

sub post_login ($c) {
    my $username = $c->stash->{form_username} = $c->param('username');
    my $password = $c->stash->{form_password} = $c->param('password');
    my $return   = $c->stash->{form_return}   = $c->param('return_url');

    # Find the user -- if they have an @, assume it's an email addresss.
    my $person = $c->db->resultset('Person')->find( index($username, '@') == -1
        ? { username => $username }
        : { email    => $username }
    );

    # Check that we have a user account and the password matches, otherwise redirect without login.
    $c->redirect_to( $return ) unless $person;
    $c->redirect_to( $return ) unless $person->auth_password->check_password( $password );

    # The user checks out, log them in.
    $c->session->{uid} = $person->id;  # Set the user cookie for the login.
    $c->redirect_to( $return );        # Send them to the page they were on with a refresh.
}

sub post_logout ($c) {
    delete $c->session->{uid};
    $c->redirect_to( $c->url_for( 'homepage' ));

}

1;
