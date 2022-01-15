#!/usr/bin/env perl
use Mojo::Base '-signatures';
use BlogDB::Web::Test;

my $t = Test::Mojo::BlogDB->new('BlogDB::Web');

# Try creating a valid account, ensure it exists in the DB.
$t->post_ok( '/register', form => { 
        username => 'fred',
        email    => 'fred@blog.com',
        password => 'SuperSecure',
        confirm  => 'SuperSecure',
    })->status_is( 302 
    )->code_block( sub {
        is( scalar(@{shift->stash->{errors}}), 0, 'No errors' );
    })->code_block( sub {
        is( shift->app->db->resultset('Person')->search( { username => 'fred'})->count, 1, 'User created.');
    })->get_ok( '/'
    )->code_block( sub {
        is(shift->stash->{person}->username, 'fred', 'Got the fred after login...');
    })->stash_has( { entries => [ ]}, "Blog entry array ref exists.");

# New Session, verify it isn't logged in.
$t = Test::Mojo::BlogDB->new('BlogDB::Web');

$t->get_ok( '/' )->code_block( sub { is(shift->stash->{person}, undef, "Not logged in.") });

$t->post_ok( '/login', form => { username => 'fred', password => 'SuperSecure'})
    ->get_ok( '/')
    ->code_block( sub { is(shift->stash->{person}->username, 'fred', 'Logged in')});

done_testing();