package BlogDB::Web::Controller::User;
use Mojo::Base 'Mojolicious::Controller', -signatures;

# Do user listing for logged in or not logged in user.
# User to show is :name
sub get_user ($c) {
    $c->set_template( 'user/index' );
    
    $c->stash->{profile} = $c->db->resultset('Person')->find({
        username => $c->param('name'),
    });

    $c->stash->{profile_about} = $c->stash->{profile}->setting('user_profile');

}

# Do follow/unfollow for currently logged in user.
# User to follow is :name
sub post_follow ($c) {
    $c->set_template( 'user/index' );


    my $follow = $c->db->resultset('Person')->find({
        id => $c->param('person_id'),
    });

    return 0 unless $follow;

    # TODO: Throw an error if we don't have {person}->id, or $blog.
    $c->stash->{person}->create_related('person_follow_person_maps_follow', {
        person_id => $c->stash->{person}->id,
        follow_id => $follow->id,
    });

    $c->redirect_to( $c->url_for( 'user', name => $follow->username ) );
}


sub post_unfollow ($c) {
    my $follow = $c->db->resultset('Person')->find({
        id => $c->param('person_id'),
    });

    return 0 unless $follow;

    # TODO: Throw an error if we don't have {person}->id, or $blog.

    $c->db->resultset('PersonFollowPersonMap')->search({
        person_id => $c->stash->{person}->id,
        follow_id => $follow->id,
    })->delete;
    
    $c->redirect_to( $c->url_for( 'user', name => $follow->username ) );
}

# Set settings for currently logged in user.
sub get_settings ($c) {
    $c->set_template( 'user/settings' );

    my $is_adult = $c->stash->{form_adult}   = $c->stash->{person}->setting('can_view_adult');
    my $profile  = $c->stash->{form_profile} = $c->stash->{person}->setting('user_profile');

}

sub post_settings ($c) {
    $c->set_template( 'user/settings' );

    my $is_adult = $c->stash->{form_adult} = $c->param('is_adult') ? 1 : 0;
    my $profile  = $c->stash->{form_profile} = $c->param('profile');

    $c->stash->{person}->setting( can_view_adult => $is_adult );
    $c->stash->{person}->setting( user_profile => $profile );

    $c->redirect_to( $c->url_for( 'user_settings'));

}

sub get_settings_email ($c) {
    $c->set_template( 'user/settings/email' );

}

sub post_email ($c) {
    $c->set_template( 'user/settings/email' );

    my $email = $c->stash->{form_email}    = $c->param('email');
    my $pass  = $c->stash->{form_password} = $c->param('password');

    push @{$c->stash->{errors}}, "Email is required." unless $email;
    push @{$c->stash->{errors}}, "Password is required." unless $pass;

    return 0 if $c->stash->{errors};

    push @{$c->stash->{errors}}, "Incorrect password"
        unless $c->stash->{person}->auth_password->check_password($pass);

    return 0 if $c->stash->{errors};

    $c->stash->{person}->email( $email );
    $c->stash->{person}->update;
    
    $c->redirect_to( $c->url_for( 'user_settings_email'));
}

sub get_settings_password ($c) {
    $c->set_template( 'user/settings/password' );

}

sub post_password ($c) {
    $c->set_template( 'user/settings/password' );
    
    my $old_pass = $c->stash->{form_password}     = $c->param('password');
    my $new_pass = $c->stash->{form_new_password} = $c->param('new_password');
    my $confirm  = $c->stash->{form_confirm}      = $c->param('confirm');

    push @{$c->stash->{errors}}, "Current password is required" unless $old_pass;
    push @{$c->stash->{errors}}, "New password is required"     unless $new_pass;
    push @{$c->stash->{errors}}, "Password confirm is required" unless $new_pass;

    return 0 if $c->stash->{errors};
    
    push @{$c->stash->{errors}}, "Incorrect password"
        unless $c->stash->{person}->auth_password->check_password($old_pass);

    return 0 if $c->stash->{errors};

    push @{$c->stash->{errors}}, "Password must be at least 7 chars" unless 7 > $new_pass;
    push @{$c->stash->{errors}}, "Password and confirm password must match." unless $new_pass eq $confirm;
    
    return 0 if $c->stash->{errors};

    $c->stash->{person}->auth_password->update_password( $new_pass );

    # Throw the user out so they must login with their new password.
    delete $c->session->{uid};
    $c->redirect_to( $c->url_for( 'homepage' ));
}

sub get_settings_following ($c) {
    $c->set_template( 'user/settings/following' );



}

sub post_following ($c) {
    $c->set_template( 'user/settings/following' );

    my $follow = $c->stash->{person}->find_related('person_follow_blog_maps', {
        blog_id => $c->param('blog_id'),
    });

    if ( $c->param('is_public')) {
        $follow->is_public(1);
    } else {
        $follow->is_public(0);
    }
    $follow->update;
}


sub post_bio ($c) {
    $c->set_template( 'user/settings' );

}

sub post_about ($c) {
    $c->set_template( 'user/settings' );

}


1;
