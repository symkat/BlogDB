package BlogDB::Web::Command::scan_blogs;
use Mojo::Base 'Mojolicious::Command';

use Mojo::Promise;
use Mojo::Util qw( getopt );

has description => 'Schedule scans for new blog content.';
has usage => <<"USAGE";
$0 scan_blogs [OPTIONS]
OPTIONS:
    -n --noop   Do not schedule jobs, just show what would be done
    -q --quet   Supress output

USAGE


sub run {
    my ( $self, @args ) = @_;

    getopt( \@args,
        'n|noop!'  => \my $noop,
        'q|quiet!' => \my $quiet,
    );

    my $app = $self->app;

    my $rs = $app->db->resultset('Blog')->search({});

    while ( my $blog = $rs->next ) {
        print "Checking " . $blog->title . "\n"
            unless $quiet;

        if ( ! $blog->last_updated ) {
            print "No last_updated date for this entry, setting to yesterday\n"
                unless $quiet;
            $blog->last_updated( DateTime->now->subtract( days => 1 ));
            if ( $noop ) {
                print "[noop] Would set last_update to yesterday.\n"
                    unless $quiet;
            } else {
                $blog->update;
            }
        }

        my $delta = DateTime->now - $blog->last_updated;

        # How long ago was this last scanned?
        my ( $days, $hours )= $delta->in_units(qw( days hours ));
        $hours += $days * 24;

        # Do not update if it has been less than 12 hours since the last update.
        next unless $hours >= 12;

        # Okay, do the update.
        print "Creating job to update this blog.\n"
            unless $quiet;
        if ( $noop ) {
            print "[noop] Would enqueue this blog for update.\n"
                unless $quiet;
        } else {
            # TODO: The screengrab stuff should run if there was updates to the blog
            #       entries.
            $app->minion->enqueue( populate_blog_entries => [ $blog->id, 'prod']);
            $blog->last_updated( DateTime->now );
            $blog->update;
        }
    }
}

1;