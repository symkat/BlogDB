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
    $c->set_template( 'blog/new/index' );

    push @{$c->stash->{blogs}}, $c->db->resultset('PendingBlog')->all;
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
    $c->set_template( 'blog/new/item' );

    my $blog_id = $c->stash->{blog_id}  = $c->param('id');
    my $blog    = $c->stash->{blog_obj} = $c->db->resultset('PendingBlog')->find( $blog_id );
    

    # Populate the form with the current values.

    $c->stash->{form_title}   = $blog->title; 
    $c->stash->{form_url}     = $blog->url;  
    $c->stash->{form_img_url} = $blog->img_url;
    $c->stash->{form_rss_url} = $blog->rss_url;
    $c->stash->{form_tagline} = $blog->tagline;
    $c->stash->{form_about}   = $blog->about;

    # Make sure we have added the tags to the page.
    push @{$c->stash->{tags}}, $c->db->resultset('Tag')->all;

}

sub post_edit_new_blog ($c) {

    my $blog_id = $c->stash->{blog_id}  = $c->param('id');
    my $blog    = $c->stash->{blog_obj} = $c->db->resultset('PendingBlog')->find( $blog_id );


    # TODO: This section should be guarded by checking that the user
    #       has a UUID that allows editing, or is a logged in user with
    #       such permissions as allows editing it.
    $c->stash->{form_title}   = $c->param("title"); 
    $c->stash->{form_url}     = $c->param("url");  
    $c->stash->{form_img_url} = $c->param("img_url");
    $c->stash->{form_rss_url} = $c->param("rss_url");
    $c->stash->{form_tagline} = $c->param("tagline");
    $c->stash->{form_about}   = $c->param("about");


    $blog->title( $c->stash->{form_title} );
    $blog->url( $c->stash->{form_url} );
    $blog->img_url( $c->stash->{form_img_url} );
    $blog->rss_url( $c->stash->{form_rss_url} );
    $blog->tagline( $c->stash->{form_tagline} );
    $blog->about( $c->stash->{form_about} );

    $blog->update;

    # Send the user back to the standard GET path.
    $c->redirect_to( $c->url_for( 'edit_new_blog', id => $blog->id ) );

}

1;
