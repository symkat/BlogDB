#!/usr/bin/env perl
#==
# Test to confirm we can log into an account after it has been created.
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

# Ensure that the login form exists on the home page.
$t->get_ok( '/')
    ->element_exists( 'form[name="login"]')
    ->element_exists( 'input[type="hidden"][name="return_url"]')
    ->element_exists( 'input[name="username"]')
    ->element_exists( 'input[name="password"]')
    ->element_exists_not( 'a[href="/user/settings"]' );

# Confirm login behavior.
$t->post_ok( '/login', form => { username => 'fred', password => 'SuperSecure', return_url => '/'})
    ->status_is( 302 )                                  # Redirect status is set
    ->header_is( 'location', '/')                       # Redirect location is what return_url was
    ->get_ok('/')                                       # Manually go to /
    ->element_exists( 'a[href="/user/settings"]' )      # Confirm the user settings button showing we're logged in.
    ->element_exists_not( 'form[name="login"]');        # Confirm the login form is no longer present.

done_testing;