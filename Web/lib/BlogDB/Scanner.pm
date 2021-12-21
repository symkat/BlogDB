package BlogDB::Scanner;
use Moo;
use LWP::UserAgent;
use HTML::TreeBuilder;

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
        $_[0]->attr('property') eq $property
    });

    return $elem->attr('content');

}

sub title {
    my ( $self ) = @_;

    return $self->_find_meta_property( 'og:title' );
}
        
sub description {
    my ( $self ) = @_;

    return $self->_find_meta_property( 'og:description' );
}

sub rss_url {
    my ( $self ) = @_;

    # Try /feed - WordPress
    my $res = $self->ua->get( $self->url . "/feed" );
    if ( $res->is_success and $res->content_type eq 'application/rss+xml' ) {
        return $self->url . "/feed";
    }
    
    # Try /feed/posts/default - Blogger
    $res = $self->ua->get( $self->url . "/feeds/posts/default" );
    if ( $res->is_success and $res->content_type eq 'application/atom+xml' ) {
        return $self->url . "/feeds/posts/default";
    }

    return "";
}

1;