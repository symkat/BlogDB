package BlogDB::Scanner;
use Moo;
use Mojo::Feed;
use LWP::UserAgent;
use HTML::TreeBuilder;
use Try::Tiny;
use URI;

has ua => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { 
        return LWP::UserAgent->new(
            agent => 'BlogDB::Scanner',
        );
    }
);

has url  => ( is => 'rw' );
has raw  => ( is => 'rw' );
has res  => ( is => 'rw' );
has tree => ( is => 'rw' );

has uri  => (
    is       => 'ro',
    lazy     => 1,
    init_arg => undef,
    builder  => sub {
        my ( $self ) = @_;

        my $uri = URI->new( $self->url );
        return $uri->canonical->as_string;
    },
);

sub scan {
    my ( $self, $url ) = @_;

    # Promote self into an object if we were called as a class method.
    $self = __PACKAGE__->new
        unless ref($self) eq __PACKAGE__;

    $self->url( $url );
    $self->res( $self->ua->get($url));
    $self->raw( $self->res->decoded_content);
    $self->tree( HTML::TreeBuilder->new_from_content($self->raw));

    return $self;
}

sub _find_meta_property {
    my ( $self, $property ) = @_;

    my ( $elem ) = $self->tree->look_down( _tag => 'meta', sub {
        $_[0]                   and 
        $_[0]->can('attr')      and 
        $_[0]->attr('property') and 
        $_[0]->attr('content')  and
        $_[0]->attr('property') eq $property
    });

    return undef unless $elem;

    return $elem->attr('content');
}

sub title {
    my ( $self ) = @_;

    my ( $first ) = grep { defined } map {
        $self->_find_meta_property( $_ )
    } ( qw( og:title title ) );

    return $first;
}

# Find description -- fall back to title
sub description {
    my ( $self ) = @_;

    my ( $first ) = grep { defined } map {
        $self->_find_meta_property( $_ )
    } ( qw( og:description description og:title title ) );

    return $first;
}

# Find the RSS URL For This Website
sub rss_url {
    my ( $self ) = @_;

    my @paths = (qw(
        /feed
        /feed.rss
        /feed.atom
        /feeds/posts/default
        /rss.xml
        /atom.xml
    ));

    foreach my $path ( @paths ) {
        my $rss_url = $self->is_valid_rss($self->uri . $path);

        # We found a valid and working RSS stream.
        if ( $rss_url ) {
            return $rss_url;
        }
    }

    return undef;
}


sub is_valid_rss {
    my ( $self, $rss_url ) = @_;
    
    my $feed = try {
        Mojo::Feed->new( url => $rss_url )->is_valid;
        Mojo::Feed->new( url => $rss_url );
    };

    return unless $feed;

    return $feed->url if $feed->is_valid;
}

1;
