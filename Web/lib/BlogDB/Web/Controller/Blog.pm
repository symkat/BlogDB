package BlogDB::Web::Controller::Blog;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Data::UUID;

sub _slug_to_id ($self, $slug) {
    # /:id
    # /:id-
    # /:id-anything

    if ( $slug =~ /^(\d+)-?$/ ) {
        return $1;
    } elsif ( $slug =~ /^(\d+)-.+$/ ) {
        return $1;
    }

    return "";
}

sub get_view_blog ($c) {
    $c->set_template( 'blog/index' );

    my $blog_id = $c->_slug_to_id($c->param('slug'));
    my $blog    = $c->stash->{blog} = $c->db->resultset('Blog')->find( $blog_id );
    
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

    $c->minion->enqueue( populate_blog_screenshot => [ $blog->id, 'pending' ]);

    $c->redirect_to( $c->url_for( 'edit_new_blog', id => $blog->id ) );
}

sub get_edit_new_blog ($c) {
    $c->set_template( 'blog/new/item' );

    my $blog_id = $c->stash->{blog_id} = $c->param('id');
    my $blog    = $c->stash->{blog}    = $c->db->resultset('PendingBlog')->find( $blog_id );
    

    # Populate the form with the current values.

    $c->stash->{form_title}   = $blog->title; 
    $c->stash->{form_url}     = $blog->url;  
    $c->stash->{form_rss_url} = $blog->rss_url;
    $c->stash->{form_tagline} = $blog->tagline;
    $c->stash->{form_about}   = $blog->about;
    $c->stash->{form_adult}   = $blog->is_adult;

    my %seen = map { $_->tag_id => 1 } $blog->search_related('pending_blog_tag_maps', {})->all;
    foreach my $tag ( $c->db->resultset('Tag')->all ) {
        push @{$c->stash->{tags}}, {
            id      => $tag->id,
            name    => $tag->name,
            checked => $seen{$tag->id} ? 1 : 0, 
        };

    }

    foreach my $post ( $blog->search_related('pending_blog_entries')->all ) {
        push @{$c->stash->{posts}}, {
            title => $post->title,
            url   => $post->url,
            date  => $post->publish_date,
        };
    }

}

sub post_edit_new_blog ($c) {

    my $blog_id = $c->stash->{blog_id} = $c->param('id');
    my $blog    = $c->stash->{blog}    = $c->db->resultset('PendingBlog')->find( $blog_id );


    # TODO: This section should be guarded by checking that the user
    #       has a UUID that allows editing, or is a logged in user with
    #       such permissions as allows editing it.
    $c->stash->{form_title}   = $c->param("title"); 
    $c->stash->{form_url}     = $c->param("url");  
    $c->stash->{form_rss_url} = $c->param("rss_url");
    $c->stash->{form_tagline} = $c->param("tagline");
    $c->stash->{form_about}   = $c->param("about");
    $c->stash->{form_adult}   = $c->param("is_adult") ? 1 : 0;

    $blog->title   ( $c->stash->{form_title}   );
    $blog->url     ( $c->stash->{form_url}     );
    $blog->rss_url ( $c->stash->{form_rss_url} );
    $blog->tagline ( $c->stash->{form_tagline} );
    $blog->about   ( $c->stash->{form_about}   );
    $blog->is_adult( $c->stash->{form_adult}   );

    $blog->update;

    # Get Posts from RSS Feed.
    $c->minion->enqueue( populate_blog_entries => [ $blog->id, 'pending' ]);

    # Remove all tags, then add the tags we have set.
    $blog->search_related('pending_blog_tag_maps')->delete;
    foreach my $tag_id ( @{$c->every_param('tags')}) {
        $blog->create_related('pending_blog_tag_maps', {
            tag_id => $tag_id,
        });
    }

    # Send the user back to the standard GET path.
    $c->redirect_to( $c->url_for( 'edit_new_blog', id => $blog->id ) );
}

sub post_publish_new_blog ($c) {
    my $pb = $c->db->resultset('PendingBlog')->find( $c->param('id') );

    my $blog = $c->db->resultset('Blog')->create({
        title    => $pb->title, 
        url      => $pb->url,
        img_url  => $pb->img_url,
        rss_url  => $pb->rss_url,
        tagline  => $pb->tagline,
        about    => $pb->about,
        is_adult => $pb->is_adult,
    });

    my @tags = $pb->search_related('pending_blog_tag_maps')->all;
    foreach my $tag ( @tags ) {
        $blog->create_related('blog_tag_maps', {
            tag_id => $tag->tag_id,
        });
        $tag->delete;
    }
    $pb->search_related('pending_blog_entries')->delete;
    $pb->delete;

    $c->minion->enqueue( populate_blog_entries    => [ $blog->id, 'prod' ]);
    $c->minion->enqueue( populate_blog_screenshot => [ $blog->id, 'prod' ]);

    $c->redirect_to( $c->url_for( 'view_blog', slug => $blog->slug ) );
}

1;
