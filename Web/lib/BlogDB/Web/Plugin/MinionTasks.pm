package BlogDB::Web::Plugin::MinionTasks;
use Mojo::Base 'Mojolicious::Plugin', -signatures;
use WebService::WsScreenshot;
use Minion;
use LWP::UserAgent;
use XML::RSS;
use Try::Tiny;
use Mojo::File qw( tempfile );
use File::Path qw( make_path );
use BlogDB::Scanner;
use Mojo::Feed;
use DateTime;

sub register ( $self, $app, $config ) {

    my $screenshot = WebService::WsScreenshot->new(
        base_url => $app->config->{ws_screenshot}->{base_url},
    );

    $app->plugin( Minion => { Pg => $app->config->{database}->{minion} } );
    $app->plugin( 'Minion::Admin', route => $config->{route});

    $app->helper( extract_feed => sub ( $c, $url ) {
        my $rss = XML::RSS->new;
        my $ua  = LWP::UserAgent->new(
            timeout => 60,
            agent   => 'Mozilla/5.0 BlogDB.org RSS Reader',
        );

        my $res = $ua->get( $url );

        return [ ] unless $res->is_success;

        my $did_parse_content = try {
            $rss->parse( $res->decoded_content );
        } catch {
            warn "Failed to parse $url: $_";
            return 0;
        };

        return [ ] unless $did_parse_content;

        my @items;
        foreach my $item ( @{$rss->{items}} ) {
            push @items, {
                title => $item->{title},
                link  => $item->{link},
                date  => $item->{pubDate},
            };
        }
        return [ @items ];
    });

    $app->minion->add_task(populate_blog_screenshot => sub ( $job, $blog_id, $type ) {
        my $rs1 = $type eq 'pending' ? 'PendingBlog' : 'Blog';
        my $blog = $job->app->db->resultset($rs1)->find( $blog_id );

        if ( ! $blog ) {
            die "Error: Failed to load blog from $rs1 for id $blog_id";
        }

        make_path( $job->app->static->paths->[0] . '/screenshots/' );
        my $out  = tempfile( 
            DIR    => $job->app->static->paths->[0] . '/screenshots/',
            SUFFIX => '.jpg',
            UNLINK => 0,
        );

        $screenshot->store_screenshot( 
            url      => $blog->url, 
            out_file => $out->to_string,
        );

        $blog->img_url( '/screenshots/' . $out->basename );
        $blog->update;

        $blog->setting( 'minion-screenshot' => time );

    });

    $app->minion->add_task(populate_blog_data => sub ( $job, $blog_id, $type ) {
        my $rs1 = $type eq 'pending' ? 'PendingBlog' : 'Blog';
        my $blog = $job->app->db->resultset($rs1)->find( $blog_id );

        if ( ! $blog ) {
            die "Error: Failed to load blog from $rs1 for id $blog_id";
        }

        my $data = BlogDB::Scanner->scan( $blog->url );

        $blog->url    ( $data->uri         );
        $blog->tagline( $data->description );
        $blog->title  ( $data->title       );
        $blog->rss_url( $data->rss_url     );

        $blog->update;
        
        $blog->setting( 'minion-data_scrape' => time );
    });
    
    $app->minion->add_task(populate_blog_entries => sub ( $job, $blog_id, $type ) {
        my $rs1 = $type eq 'pending' ? 'PendingBlog'          : 'Blog';
        my $rs2 = $type eq 'pending' ? 'PendingBlogEntry'     : 'BlogEntry';
        my $rs3 = $type eq 'pending' ? 'pending_blog_entries' : 'blog_entries';

        my $blog = $job->app->db->resultset($rs1)->find( $blog_id );
        
        if ( ! $blog ) {
            die "Error: Failed to load blog from $rs1 for id $blog_id";
        }

        # Don't continue if we don't have an RSS URL, however update
        # the time so the front end switches to show the edit page after
        # failure to get rss feeds.
        if ( ! $blog->rss_url ) {
            $blog->setting( 'minion-rss_scrape' => time );
            return;
        }

        my $feed = Mojo::Feed->new( url => $blog->rss_url );

        $feed->items->each( sub {
            my $entry_count = $job->app->db->resultset($rs2)->search({
                url => $_->link,
            })->count;

            return if $entry_count >= 1;

            $blog->create_related( $rs3, {
                title        => $_->title,
                url          => $_->link,
                publish_date => DateTime->from_epoch( epoch => $_->published),
            });
        });

        $blog->last_updated( DateTime->now );
        $blog->update;
        $blog->setting( 'minion-rss_scrape' => time );
    });

    $app->minion->add_task( initial_blog_import => sub ( $job, $blog_id ) {
        my $dep_id = $job->minion->enqueue( populate_blog_data => [ $blog_id, 'pending' ]);
        
        $job->minion->enqueue( populate_blog_screenshot => [ $blog_id, 'pending' ], {
            parents => [ $dep_id ],
        });

        $job->minion->enqueue( populate_blog_entries => [ $blog_id, 'pending' ], {
            parents => [ $dep_id ],
        });

    });

    $app->minion->add_task( refresh_blog_data => sub ( $job, $blog_id ) {
        my $last_post_time = $job->app->db->resultset('Blog')->find($blog_id)->last_post->publish_date;

        my $id = $job->minion->enqueue( populate_blog_entries => [ $blog_id, 'prod' ]);

        $job->minion->enqueue( screenshot_on_update => [ $blog_id, $last_post_time ], {
            parents => [ $id ],
        });
    });
    
    $app->minion->add_task( screenshot_on_update => sub ( $job, $blog_id, $old_time ) {
        my $last_post_time = $job->app->db->resultset('Blog')->find($blog_id)->last_post->publish_date;

        return if $last_post_time eq $old_time;

        $job->minion->enqueue( populate_blog_screenshot => [ $blog_id, 'pending' ]);
    });
}

1;