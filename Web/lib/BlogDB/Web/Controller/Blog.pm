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

    my $blog = $c->stash->{blog} = $c->db->resultset('Blog')->find(
        $c->_slug_to_id($c->param('slug'))
    );
}

sub get_edit_blog ($c) {
    $c->set_template( 'blog/edit' );

    my $blog = $c->stash->{blog} = $c->db->resultset('Blog')->find(
        $c->_slug_to_id($c->param('slug'))
    );

    $c->stash->{form_title}   = $blog->title; 
    $c->stash->{form_url}     = $blog->url;  
    $c->stash->{form_rss_url} = $blog->rss_url;
    $c->stash->{form_tagline} = $blog->tagline;
    $c->stash->{form_about}   = $blog->about;
    $c->stash->{form_adult}   = $blog->is_adult;
    
    # I should add this to the PendingBlog/Blog models - all tags + checked / not checked status.
    my %seen = map { $_->tag_id => 1 } $blog->search_related('blog_tag_maps', {})->all;
    foreach my $tag ( $c->db->resultset('Tag')->all ) {
        push @{$c->stash->{tags}}, {
            id      => $tag->id,
            name    => $tag->name,
            checked => $seen{$tag->id} ? 1 : 0, 
        };

    }
}

sub post_edit_blog ($c) {
    $c->set_template( 'blog/edit' );

    my $blog = $c->stash->{blog} = $c->db->resultset('Blog')->find(
        $c->_slug_to_id($c->param('slug'))
    );

    $blog->title   ( $c->param('title')             );
    $blog->url     ( $c->param('url')               );
    $blog->rss_url ( $c->param('rss_url')           );
    $blog->tagline ( $c->param('tagline')           );
    $blog->about   ( $c->param('about')             );
    $blog->is_adult( $c->param('is_adult') ? 1 : 0  );

    $blog->update;

    # Remove all tags, then add the tags we have set.
    $blog->search_related('blog_tag_maps')->delete;
    foreach my $tag_id ( @{$c->every_param('tags')}) {
        $blog->create_related('blog_tag_maps', {
            tag_id => $tag_id,
        });
    }

    # Send the user back to the standard GET path.
    $c->redirect_to( $c->url_for( 'view_blog', slug => $blog->slug ) );
}

sub post_blog_follow ($c) {
    my $blog = $c->db->resultset('Blog')->find($c->param('blog_id'));

    # TODO: Throw an error if we don't have {person}->id, or $blog.
    $c->stash->{person}->create_related('person_follow_blog_maps', {
        blog_id => $blog->id,
    });

    $c->redirect_to( $c->url_for( 'view_blog', slug => $blog->slug ) );
}

sub post_blog_unfollow ($c) {
    my $blog = $c->db->resultset('Blog')->find($c->param('blog_id'));

    # TODO: Throw an error if we don't have {person}->id, or $blog.

    $c->db->resultset('PersonFollowBlogMap')->search({
        person_id => $c->stash->{person}->id,
        blog_id   => $blog->id,
    })->delete;
    
    $c->redirect_to( $c->url_for( 'view_blog', slug => $blog->slug ) );
}

sub post_blog_comment ($c) {
    my $blog_id = $c->stash->{form_blog_id} = $c->param('blog_id');
    my $message = $c->stash->{form_message} = $c->param('message');
    my $rev_pos = $c->stash->{form_rev_pos} = $c->param('rev_pos');
    my $rev_neg = $c->stash->{form_rev_neg} = $c->param('rev_neg');
    my $parent  = $c->stash->{form_parent}  = $c->param('parent_id');

    # pos = 1, neg = -1, otherwise 0
    my $vote = $rev_pos ? 1 : ( $rev_neg ? -1 : 0 );

    $c->stash->{person}->create_related('messages', {
        blog_id   => $blog_id,
        content   => $message,
        parent_id => $parent,
        vote      => $vote,
    });
    
    $c->redirect_to( $c->url_for( 'view_blog', slug => $blog_id ) );
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
    my $person  = $c->stash->{person};

    # We can continue if:
    # 1: We have an edit_token, and it matches the blog->edit_token.
    # 2: We are a logged in user and we are the blog->submitter.
    # 3: We are a logged in user and we have can_manage_blogs
    my $passes_tests = 0;

    if ( $person && $person->setting('can_manage_blogs') ) {
        $passes_tests = 1;
        push @{$c->stash->{authorization}}, 'setting:can_manage_blogs';
    }
    if ( $blog->submitter_id && $blog->submitter_id == $person->id ) {
        push @{$c->stash->{authorization}}, 'submitter';
        $passes_tests = 1;
    }
    if ( $blog->edit_token && $c->session->{edit_token} ) {
        if ( $blog->edit_token eq $c->session->{edit_token} ) {
            push @{$c->stash->{authorization}}, 'token';
            $passes_tests = 1;
        }
    }

    # Throw out any users who don't meet the conditions set out
    # above.
    if ( not $passes_tests ) {
        push @{$c->stash->{errors}}, 'Not Authorized.';
        $c->redirect_to( $c->url_for( 'homepage' ) );
        return 0;
    }

    # Do the update in a transaction.
    $c->db->storage->schema->txn_do( sub {
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
    });

    # Send the user back to the standard GET path.
    $c->redirect_to( $c->url_for( 'edit_new_blog', id => $blog->id ) );
}

sub post_publish_new_blog ($c) {
    my $pb = $c->db->resultset('PendingBlog')->find( $c->param('id') );

    push @{$c->stash->{errors}}, 'No such blog id.'
        unless $pb;

    push @{$c->stash->{errors}}, 'Not Authorized.'
        unless $c->stash->{person}->setting( 'can_manage_blogs' );

    if ( @{$c->stash->{errors} || []} ) {
        $c->redirect_to( $c->url_for( 'homepage' ) );
        return 0;
    }

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
