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
        return state $db = BlogDB::DB->connect($self->config->{database}->{blogdb});
    });

    # Create $self->set_template
    $self->helper( set_template => sub ($c, $name) {
        $c->stash->{template} = sprintf( "%s/%s", $c->config->{template_dir}, $name );
    });

    # Get the router.
    my $r = $self->routes;

    # Create a dispatch chain that requires the user is logged in.
    my $auth = $r->under( '/' => sub ($c) {
        
        # Login via session cookie.
        if ( $c->session('uid') ) {
            my $person = $c->db->resultset('Person')->find( $c->session('uid') );

            if ( $person && $person->is_enabled ) {
                $c->stash->{person} = $person;
                return 1;
            }
            $c->redirect_to( $c->url_for( 'auth_login' ) );
            return undef;
        }

        $c->redirect_to( $c->url_for( 'auth_login' ) );
        return undef;
    });

    # Home Page
    $r->get('/')->to( 'Root#get_homepage' )->name('homepage');

    # Standard user stuff: register, forgot password, login and logout.
    $r->get ( '/register'     )->to( 'Root#get_register' )->name('register');
    $r->post( '/register'     )->to( 'Root#post_register')->name('do_register');
    $r->get ( '/forgot'       )->to( 'Root#get_forgot'   )->name('forgot_password');
    $r->post( '/forgot'       )->to( 'Root#post_forgot'  )->name('do_forgot_password');
    $r->get ( '/forgot/:token')->to( 'Root#get_reset'    )->name('reset_password');
    $r->post( '/forgot/:token')->to( 'Root#post_reset'   )->name('do_reset_password');
    $r->post( '/login'        )->to( 'Root#post_login'   )->name('do_login');
    $r->post( '/logout'       )->to( 'Root#post_logout'  )->name('do_logout');

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
    $r->get    ( '/blog/:name'            )->to( 'Blog#get_blog'      )->name( 'blog'             );
    $auth->post( '/blog/:name/follow'     )->to( 'Blog#post_follow'   )->name( 'do_follow_blog'   );
    $auth->post( '/blog/:name/unfollow'   )->to( 'Blog#post_unfollow' )->name( 'do_unfollow_blog' );
    $auth->get ( '/blog/:name/settings'   )->to( 'Blog#get_settings'  )->name( 'blog_settings'    );
    $auth->post( '/blog/:name'            )->to( 'Blog#post_settings' )->name( 'do_blog_settings' );
    $auth->post( '/blog/:name/publish'    )->to( 'Blog#post_publish'  )->name( 'do_publish'       );
    $auth->post( '/blog/:name/unpublish'  )->to( 'Blog#post_unpublish')->name( 'do_unpublish'     );

    # /new/
    $r->post   ( '/new'               )->to( 'Create#post_new'      )->name( 'do_add_new_blog'   );
    $r->get    ( '/new/:name'         )->to( 'Create#get_new_blog'  )->name( 'update_new_blog'   );
    $r->post   ( '/new/:name'         )->to( 'Create#post_new_blog' )->name( 'do_update_new_blog');
    $auth->post( '/new/:name/push'    )->to( 'Create#post_push_blog')->name( 'do_push_new_blog'  );

    # /tags/
    $r->get    ( '/tags'         )->to( 'Tags#get_tags'        )->name( 'tags'           );
    $auth->post( '/tags/suggest' )->to( 'Tags#post_suggest_tag')->name( 'do_suggest_tag' );
    $auth->post( '/tags/vote'    )->to( 'Tags#post_vote_tag'   )->name( 'do_vote_tag'    );
    $auth->post( '/tags/delete'  )->to( 'Tags#post_delete_tag' )->name( 'do_delete_tag'  );

}

1;
