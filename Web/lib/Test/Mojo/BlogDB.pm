package Test::Mojo::BlogDB;
use parent 'Test::Mojo';
use Data::Dumper;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->app->hook( after_dispatch => sub {
        my ( $c ) = @_;
        $self->stash( $c->stash );
    });

    return $self;
}

sub stash {
    my $self = shift;
    $self->{stash} = shift if @_;
    return $self->{stash};
}

sub code_block  {
    my ( $t, $code ) = @_;

    $code->($t);

    return $t;
}

1;