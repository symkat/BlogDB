package BlogDB::Web;
use Mojo::Base 'Mojolicious', -signatures;
use BlogDB::DB;

sub startup ($self) {

    # Load config, this will give us $self->config.
    $self->plugin('NotYAMLConfig', { file => 'blogdb.yml' });

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

    $self->plugin( 'BlogDB::Web::Plugin::MinionTasks');

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
                return 1;
            }
        }

        return 1;
    });

    # Only allow logged in users to access the page.
    my $auth = $r->under( '/' => sub ($c) {

        return 1 if $c->stash->{person};

        $c->redirect_to( $c->url_for( 'homepage' ) );
        return undef;
    });

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
    $r->get    ( '/user/:name'            )->to( 'User#get_user'     )->name( 'user'             );
    $auth->post( '/user/:name/follow'     )->to( 'User#post_follow'  )->name( 'do_follow_user'   );
    $auth->post( '/user/:name/unfollow'   )->to( 'User#post_unfollow')->name( 'do_unfollow_user' );
    $auth->get ( '/user/settings'         )->to( 'User#get_settings' )->name( 'user_settings'    );
    $auth->post( '/user/settings/bio'     )->to( 'User#post_bio'     )->name( 'do_user_bio'      );
    $auth->post( '/user/settings/about'   )->to( 'User#post_about'   )->name( 'do_user_about'    );
    $auth->post( '/user/settings/password')->to( 'User#post_password')->name( 'do_user_password' );
    $auth->post( '/user/settings/email'   )->to( 'User#post_email'   )->name( 'do_user_email'    );

    # /blog/ routes
    $r->get    ( '/blog/new'              )->to( 'Blog#get_new_blogs'        )->name( 'new_blogs'           ); # List new blogs.
    $r->post   ( '/blog/new'              )->to( 'Blog#post_new_blog'        )->name( 'do_new_blog'         ); # Create a new blog.
    $r->get    ( '/blog/new/:id'          )->to( 'Blog#get_edit_new_blog'    )->name( 'edit_new_blog'       ); # Show edit a new blog page.
    $r->post   ( '/blog/new/:id'          )->to( 'Blog#post_edit_new_blog'   )->name( 'do_edit_new_blog'    ); # Update a new blog.
    $r->post   ( '/blog/publish/:id'      )->to( 'Blog#post_publish_new_blog')->name( 'do_publish_new_blog' ); # Publish (PendingBlog -> Blog.)

    $r->get    ( '/blog/v/:slug'          )->to( 'Blog#get_view_blog'        )->name( 'view_blog');
    $r->get    ( '/blog/e/:slug'          )->to( 'Blog#get_edit_blog'        )->name( 'edit_blog');
    $r->post   ( '/blog/e/:slug'          )->to( 'Blog#post_edit_blog'       )->name( 'do_edit_blog');

    $r->post   ( '/blog/follow'           )->to( 'Blog#post_blog_follow'       )->name( 'do_follow_blog'  );
    $r->post   ( '/blog/unfollow'         )->to( 'Blog#post_blog_unfollow'     )->name( 'do_unfollow_blog');

    $r->post   ( '/blog/comment'          )->to( 'Blog#post_blog_comment'      )->name( 'do_blog_comment');
    
#    $r->post   ( '/blog/unfollow'         )->to( 'Blog#post_blog_unfollow'     )->name( 'do_unfollow_blog');
#    $r->get    ( '/view/:id/:name'        )->to( 'Blog#get_blog'      )->name( 'blog'             ); # View A Specific Blog.
#
#    $auth->get ( '/blog/new'              )->to( 'Blog#get_new_blogs'  )->name( 'new_blogs'        ); # List pending blogs for approval.
#    $r->get    ( '/blog/new/:id/:title'   )->to( 'Blog#get_edit_blog'  )->name( 'edit_new_blog'    ); # Get the edit page for a new blog.
#    $r->post   ( '/blog/new/:name'        )->to( 'Blog#post_edit_blog' )->name( 'do_edit_new_blog' ); # Post an update with the edit page.
#
#    $auth->post( '/blog/:name/follow'     )->to( 'Blog#post_follow'   )->name( 'do_follow_blog'   );
#    $auth->post( '/blog/:name/unfollow'   )->to( 'Blog#post_unfollow' )->name( 'do_unfollow_blog' );
#    $auth->get ( '/blog/:name/settings'   )->to( 'Blog#get_settings'  )->name( 'blog_settings'    );
#    $auth->post( '/blog/:name'            )->to( 'Blog#post_settings' )->name( 'do_blog_settings' );
#    $auth->post( '/blog/:name/publish'    )->to( 'Blog#post_publish'  )->name( 'do_publish'       );
#    $auth->post( '/blog/:name/unpublish'  )->to( 'Blog#post_unpublish')->name( 'do_unpublish'     );
    

    # /tags/
    $r->get    ( '/tags'         )->to( 'Tags#get_tags'        )->name( 'tags'           );
    $auth->post( '/tags/suggest' )->to( 'Tags#post_suggest_tag')->name( 'do_suggest_tag' );
    $auth->post( '/tags/vote'    )->to( 'Tags#post_vote_tag'   )->name( 'do_vote_tag'    );
    $auth->post( '/tags/delete'  )->to( 'Tags#post_delete_tag' )->name( 'do_delete_tag'  );
    $auth->post( '/tags/approve' )->to( 'Tags#post_approve_tag')->name( 'do_approve_tag' );

}

1;
