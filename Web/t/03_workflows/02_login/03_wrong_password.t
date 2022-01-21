#!/usr/bin/env perl
#==
# Confirm a login with an invalid password on a created account.
#==
use Mojo::Base '-signatures';
use BlogDB::Web::Test;

my $t = Test::Mojo::BlogDB->new('BlogDB::Web');

# Try creating a valid account, ensure it exists in the DB.
$t->post_ok( '/register', form => { 
        username => 'fred',
        email    => 'fred@blog.com',
        password => 'SuperSecure',
        confirm  => 'SuperSecure',
    })->status_is( 302 );

# Create new session so we are not logged in.
$t = Test::Mojo::BlogDB->new('BlogDB::Web');

# Complete login and confirm we do not gain access to the account with an incorrect password.
$t->post_ok( '/login', form => { username => 'fred', password => 'VeryWrongPassword', return_url => '/'})
    ->status_is( 302 )
    ->header_is( 'location', '/')
    ->get_ok('/')
    ->element_exists_not( 'a[href="/user/settings"]' ) # There is no settings button.
    ->element_exists( 'form[name="login"]');           # We still have a login form.

done_testing;