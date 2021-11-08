#!/usr/bin/env perl
use BlogDB::Web::Test;

my $t = Test::Mojo->new('BlogDB::Web');

$t->get_ok( '/' );

# Create an account.
$t->post_ok( '/register', form => { 
        username => 'fred',
        email    => 'fred@blog.com',
        password => 'SuperSecure',
        confirm  => 'SuperSecure',
    })->status_is( 302 );

# Login works and redirects the user.
$t->post_ok( '/login', form => {
        username => 'fred',
        password => 'SuperSecure',
        confirm  => 'SuperSecure',
        return   => '/',
    })->status_is( 302 );

# Login without account throws an error
$t->post_ok( '/login', form => {
        username => 'james',
        password => 'NoPassword',
        confirm  => 'NoPassword',
        return   => '/',
    })->status_is( 500 );

done_testing();
