#!/usr/bin/env perl
#==
# Register an account and confirm the user is logged into it.
#==
use Mojo::Base '-signatures';
use BlogDB::Web::Test;

my $t = Test::Mojo::BlogDB->new('BlogDB::Web');

# Ensure we have a registration page with a valid form.
$t->get_ok( '/register')
    ->element_exists( 'form[name="register"]')
    ->element_exists( 'input[data-form="register"][name="username"]')
    ->element_exists( 'input[data-form="register"][name="email"]')
    ->element_exists( 'input[data-form="register"][name="password"]')
    ->element_exists( 'input[data-form="register"][name="confirm"]');

# Submit the form, confirm the redirect to the home page, and that we are shown as logged in.
$t->post_ok( '/register', form => { 
        username => 'fred',
        email    => 'fred@blog.com',
        password => 'SuperSecure',
        confirm  => 'SuperSecure',
    })->status_is( 302 )                           # Redirect status set
    ->header_is( 'location', '/')                  # Redirect is to home page
    ->get_ok('/')
    ->element_exists( 'a[href="/user/settings"]' ) # Settings button - we're logged in.
    ->element_exists_not( 'form[name="login"]');   # No login form - we're logged in.

done_testing();