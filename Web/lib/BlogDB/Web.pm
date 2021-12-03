package BlogDB::Web;
use Mojo::Base 'Mojolicious', -signatures;
use BlogDB::DB;
use IO::Socket::INET;

sub startup ($self) {

    # Load config, this will give us $self->config.
    # Allow an alternative config file to be set by ENV var.
    if ( $ENV{BDB_CONFIG_FILE} ) {
        $self->plugin('NotYAMLConfig', { file => $ENV{BDB_CONFIG_FILE} });
    } else {
        $self->plugin('NotYAMLConfig', { file => 'blogdb.yml' });
    }

    # Seed the secrets for session management.
    $self->secrets($self->config->{secrets});

    # Set the session cookie expires to 30 days.
    $self->sessions->default_expiration(2592000);

    # Use Text::Xslate for template rendering.
    $self->plugin(xslate_renderer => {
        template_options => {
            syntax => 'Metakolon',
        }
    });

    # The database for minion needs to be live when we start, with
    # docker we have some startup time between the DBs loading and them
    # accepting connections.  This block will wait for connections to the
    # DB to be successful before continueing with the application startup.
    if ( $ENV{BDB_DOCKER_HOST_WAIT} ) {
        while ( 1 ) {
            warn "Trying to connect to " . $ENV{BDB_DHW_MINION_HOST} . "\n"; 
            IO::Socket::INET->new(
                PeerAddr => $ENV{BDB_DHW_MINION_HOST},
                PeerPort => 5432,
                Proto    => 'tcp',
                Timeout  => 3,
            ) and last;
            sleep 3;
        }
        warn "Connection successful - continue.\n";
        while ( 1 ) {
            warn "Trying to connect to " . $ENV{BDB_DHW_DEFAULT_HOST} . "\n"; 
            IO::Socket::INET->new(
                PeerAddr => $ENV{BDB_DHW_DEFAULT_HOST},
                PeerPort => 5432,
                Proto    => 'tcp',
                Timeout  => 3,
            ) and last;
            sleep 3;
        }
        warn "Connection successful - continue.\n";
    }

    # Create $self->db as a BlogDB::DB connection.
    $self->helper( db => sub {
        return state $db = exists $ENV{BLOGDB_TESTMODE} && $ENV{BLOGDB_TESTMODE} == 1
            ? BlogDB::DB->connect( $ENV{BLOGDB_DSN}, '', '' )
            : BlogDB::DB->connect($self->config->{database}->{blogdb});
    });

    # Create $self->set_template
    $self->helper( set_template => sub ($c, $name) {
        $c->stash->{template} = sprintf( "%s/%s", $c->config->{template_dir}, $name );
    });

    # Make _public/ in the template dir be on the static path resolution.
    push @{$self->static->paths}, 'templates/' . $self->config->{template_dir} . "/_public";


    # Add the templates/$name/_public/ directory to the static paths,
    # if the directory exists.

    # Get the router.
    my $router = $self->routes;

    # Create a dispatch chain that gives us a logged in user if we have one.
    #
    # This will NOT throw out a user.
    # Templates must consider that $person is undef when no one is logged in.
    my $r = $router->under( '/' => sub ($c) {

        # Login via session cookie.
        if ( $c->session('uid') ) {
            my $person = $c->db->resultset('Person')->find( $c->session('uid') );

            if ( $person && $person->is_enabled ) {
                $c->stash->{person} = $person;
                $c->stash->{person_permissions} = {
                    can_manage_tags  => $person->setting('can_manage_tags'),
                    can_manage_blogs => $person->setting('can_manage_blogs'),
                };
                $c->stash->{person_permissions}->{can_manage_tags}   &&= 1;
                $c->stash->{person_permissions}->{can_manage_tags}   ||= 0;
                $c->stash->{person_permissions}->{can_manage_blogs}  &&= 1;
                $c->stash->{person_permissions}->{can_manage_blogs}  ||= 0;
                return 1;
            }
        }

        return 1;
    });

    # Only allow logged in users to access the page.
    my $auth = $r->under( '/' => sub ($c) {

        return 1 if $c->stash->{person};

        push @{$c->stash->{errors}}, 'Login required.';

        $c->redirect_to( $c->url_for( 'homepage' ) );
        return undef;
    });

    my $minion_auth = $auth->under( '/minion' => sub ($c) {
        return 1 if $c->stash->{person}->setting('can_see_minion');

        $c->redirect_to( $c->url_for( 'homepage' ) );
        return undef;
    });

    # Minion and helpers plugin (down here because we need the router done).
    $self->plugin( 'BlogDB::Web::Plugin::MinionTasks', { route => $minion_auth } );

    # Home Page
    $r->get('/')->to( 'Root#get_homepage' )->name('homepage');

    # Standard user stuff: register, forgot password, login and logout.
    $r->get ( '/register'     )->to( 'Root#get_register' )->name('register'          );
    $r->post( '/register'     )->to( 'Root#post_register')->name('do_register'       );
    $r->get ( '/forgot'       )->to( 'Root#get_forgot'   )->name('forgot_password'   );
    $r->post( '/forgot'       )->to( 'Root#post_forgot'  )->name('do_forgot_password');
    $r->get ( '/forgot/:token')->to( 'Root#get_reset'    )->name('reset_password'    );
    $r->post( '/forgot/:token')->to( 'Root#post_reset'   )->name('do_reset_password' );
    $r->post( '/login'        )->to( 'Root#post_login'   )->name('do_login'          );
    $r->post( '/logout'       )->to( 'Root#post_logout'  )->name('do_logout'         );

    # /user/ routes
    #$r->get    ( '/user/:name'            )->to( 'User#get_user'     )->name( 'user'             );
    #$auth->post( '/user/:name/follow'     )->to( 'User#post_follow'  )->name( 'do_follow_user'   );
    #$auth->post( '/user/:name/unfollow'   )->to( 'User#post_unfollow')->name( 'do_unfollow_user' );
    #$auth->get ( '/user/settings'         )->to( 'User#get_settings' )->name( 'user_settings'    );
    #$auth->post( '/user/settings/bio'     )->to( 'User#post_bio'     )->name( 'do_user_bio'      );
    #$auth->post( '/user/settings/about'   )->to( 'User#post_about'   )->name( 'do_user_about'    );
    #$auth->post( '/user/settings/password')->to( 'User#post_password')->name( 'do_user_password' );
    #$auth->post( '/user/settings/email'   )->to( 'User#post_email'   )->name( 'do_user_email'    );

    # /blog/ routes
    $r->get    ( '/blog/new'              )->to( 'Blog#get_new_blogs'        )->name( 'new_blogs'           ); # List new blogs.
    $r->post   ( '/blog/new'              )->to( 'Blog#post_new_blog'        )->name( 'do_new_blog'         ); # Create a new blog.
    $r->get    ( '/blog/new/:id'          )->to( 'Blog#get_edit_new_blog'    )->name( 'edit_new_blog'       ); # Show edit a new blog page.
    $r->post   ( '/blog/new/:id'          )->to( 'Blog#post_edit_new_blog'   )->name( 'do_edit_new_blog'    ); # Update a new blog.
    $auth->post( '/blog/publish/:id'      )->to( 'Blog#post_publish_new_blog')->name( 'do_publish_new_blog' ); # Publish (PendingBlog -> Blog.)
    $r->get    ( '/blog/v/:slug'          )->to( 'Blog#get_view_blog'        )->name( 'view_blog'           ); # View specific blog
    $r->get    ( '/blog/r'                )->to( 'Blog#get_view_random_blog' )->name( 'view_random_blog'    ); # 302 redirect the user to a random blog.
    $auth->get ( '/blog/e/:slug'          )->to( 'Blog#get_edit_blog'        )->name( 'edit_blog'           ); # View edit page
    $auth->post( '/blog/e/:slug'          )->to( 'Blog#post_edit_blog'       )->name( 'do_edit_blog'        ); # Post edits to blog
    $auth->post( '/blog/follow'           )->to( 'Blog#post_blog_follow'     )->name( 'do_follow_blog'      ); # Follow a blog
    $auth->post( '/blog/unfollow'         )->to( 'Blog#post_blog_unfollow'   )->name( 'do_unfollow_blog'    ); # Unfollow a blog
    $auth->post( '/blog/comment'          )->to( 'Blog#post_blog_comment'    )->name( 'do_blog_comment'     ); # Comment on blog/reply.
    
    # /tags/
    $r->get    ( '/tags'         )->to( 'Tags#get_tags'        )->name( 'tags'           );
    $auth->post( '/tags/suggest' )->to( 'Tags#post_suggest_tag')->name( 'do_suggest_tag' );
    $auth->post( '/tags/vote'    )->to( 'Tags#post_vote_tag'   )->name( 'do_vote_tag'    );
    $auth->post( '/tags/delete'  )->to( 'Tags#post_delete_tag' )->name( 'do_delete_tag'  );
    $auth->post( '/tags/approve' )->to( 'Tags#post_approve_tag')->name( 'do_approve_tag' );

}

1;
