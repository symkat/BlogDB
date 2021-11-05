package BlogDB::Web::Controller::Blog;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Data::UUID;

sub get_blog ($c) {
    $c->set_template( 'blog/index' );

}

sub post_follow ($c) {
    $c->set_template( 'blog/index' );

}

sub post_unfollow ($c) {
    $c->set_template( 'blog/index' );

}

sub get_settings ($c) {
    $c->set_template( 'blog/settings' );

}

sub post_settings ($c) {
    $c->set_template( 'blog/settings' );

}

sub post_publish ($c) {
    $c->set_template( 'blog/settings' );

}

sub post_unpublish ($c) {
    $c->set_template( 'blog/settings' );

}

# Handle New Blogs

sub get_new_blogs ($c) {

}

sub post_new_blog ($c) {


    $c->set_template( 'index' );

    my $blog_url = $c->stash->{form_url} = $c->param('url');

    # Error Checking - We have all of the information.
    push @{$c->stash->{errors}}, "URL is required." unless $blog_url;

    # TODO: Valid URL?

    return 0 if $c->stash->{errors};

    # If an anonymous user submitted the blog, make an edit token
    # for them to use.
    if ( ! exists $c->session->{edit_token} ) {
        $c->session->{edit_token} = Data::UUID->new->create_str,
    }

    my $blog = $c->db->resultset('PendingBlog')->create({
        state => 'initial',
        url   => $blog_url,
        ( exists $c->stash->{person} 
            ? ( submitter_id => $c->stash->{person}->id   )
            : ( edit_token   => $c->session->{edit_token} )
        ),
    });

    #$c->redirect_to( $c->url_for( 'do_blog_edit', id => $blog->id, title => 'new' ) );
}

sub get_edit_new_blog ($c) {

}

sub post_edit_new_blog ($c) {

}

1;
