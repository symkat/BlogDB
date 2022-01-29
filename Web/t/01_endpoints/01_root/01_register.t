#!/usr/bin/env perl
use Mojo::Base '-signatures';
use BlogDB::Web::Test;

my $t = Test::Mojo::BlogDB->new('BlogDB::Web');

# Try creating an account with an error, ensure we get the error.
$t->post_ok( '/register', form => { 
        username => 'fred',
        email    => 'fred@blog.com',
        password => 'SuperSecure',
        confirm  => 'SuperFail',
    })->status_is( 200 
    )->code_block( sub {
        is( shift->stash->{errors}->[0], 'Password & Confirmation must match.', 'Expected error thrown' );
    })->code_block( sub {
        is( shift->app->db->resultset('Person')->search( { username => 'fred'})->count, 0, 'No user created.');
    });

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
    })->stash_has( { blogs => [ ]}, "Blog entry array ref exists.");

done_testing();