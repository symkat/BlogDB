package Test::Mojo::BlogDB;
# This package subclasses Test::Mojo and sets up some
# functionality.
#
# _stash_
# The $t object will now have a stash method that returns
# the stash.
# 
# _code_block_
# The $t object will now have a code_block method that
# accepts a code block, runs it, and returns $t.
#
# This combination of stash and code_block enable a
# pattern like the following:
#  
# $t->post_ok( '/login', { user => $user, pass => $pass})
#   ->code_block( sub { 
#     my $t = shift;
#     is($t->stash->{person}->user, $user, "User saved in stash."); 
#   })->status_is( 200 );
# 
# _dump_stash_
# The $t object now has a dump_stash method that prints the
# stash to STDERR.  By default this will supress mojo-specific
# stash elements, pass a true value to dump the full stash.
# 
# $t->get_ok('/')
#   ->dump_stash(1)
#   ->status_is(200);
#
use parent 'Test::Mojo';
use Data::Dumper;
use Test::Deep;

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

sub dump_stash {
    my ( $t, $show_all ) = @_;

    if ( $show_all ) {
        warn Dumper $t->stash;
        return $t;
    }

    foreach my $key ( keys %{$t->stash}) {
        next if $key eq 'controller';
        next if $key eq 'action';
        next if $key eq 'cb';
        next if $key eq 'template';
        next if $key =~ m|^mojo\.|;

        $ds->{$key} = $t->stash->{$key};
    }
    
    warn Dumper $ds;

    return $t;
}

sub stash_has {
    my ( $t, $expect, $desc ) = @_;

    cmp_deeply( $t->stash, superhashof($expect), $desc);
}

1;