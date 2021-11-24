package BlogDB::Web::Plugin::MinionTasks;
use Mojo::Base 'Mojolicious::Plugin', -signatures;
use WebService::WsScreenshot;
use Minion;
use LWP::UserAgent;
use XML::RSS;
use Try::Tiny;
use Mojo::File qw( tempfile );
use File::Path qw( make_path );

sub register ( $self, $app, $config ) {

    my $screenshot = WebService::WsScreenshot->new(
        base_url => $app->config->{ws_screenshot}->{base_url},
    );

    $app->plugin( Minion => { Pg => $app->config->{database}->{minion} } );
    $app->plugin( 'Minion::Admin' );

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
    });
    
    $app->minion->add_task(populate_blog_entries => sub ( $job, $blog_id, $type ) {
        my $rs1 = $type eq 'pending' ? 'PendingBlog'          : 'Blog';
        my $rs2 = $type eq 'pending' ? 'PendingBlogEntry'     : 'BlogEntry';
        my $rs3 = $type eq 'pending' ? 'pending_blog_entries' : 'blog_entries';

        my $blog = $job->app->db->resultset($rs1)->find( $blog_id );

        return unless $blog->rss_url;

        my $entries = $job->app->extract_feed( $blog->rss_url );

        foreach my $entry ( @{$entries} ) {
            my $entry_count = $job->app->db->resultset($rs2)->search({
                url => $entry->{link},
            })->count;

            next if $entry_count >= 1;

            $blog->create_related( $rs3, {
                title        => $entry->{title},
                url          => $entry->{link},
                publish_date => $entry->{date},
            });
        } 
    });
}

1;