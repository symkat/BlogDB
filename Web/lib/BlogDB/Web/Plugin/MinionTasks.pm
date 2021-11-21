package BlogDB::Web::Plugin::MinionTasks;
use Mojo::Base 'Mojolicious::Plugin', -signatures;
use WebService::WsScreenshot;
use Minion;

sub register ( $self, $app, $config ) {

    my $screenshot = WebService::WsScreenshot->new(
        base_url => $app->config->{ws_screenshot}->{base_url},
    );

    $app->plugin( Minion => { Pg => $app->config->{database}->{minion} } );
    $app->plugin( 'Minion::Admin' );

    $app->minion->add_task(download_screenshot => sub ( $job, $blog_url, $blog_id ) {
        $screenshot->store_screenshot( 
            url      => $blog_url, 
            out_file => $job->app->config->{ws_screenshot}->{datadir} . "$blog_id.jpg",
        );
    });

}

1;