#!/usr/bin/env perl
#==
# Confirm a login with an invalid account doesn't work.
#==
use Mojo::Base '-signatures';
use BlogDB::Web::Test;

my $t = Test::Mojo::BlogDB->new('BlogDB::Web');

# Complete login and confirm we do not login
$t->post_ok( '/login', form => { username => 'fred', password => 'SuperSecure', return_url => '/'})
    ->status_is( 302 )
    ->header_is( 'location', '/')
    ->get_ok('/')
    ->element_exists( 'form[name="login"]'); # After login attempt, we still have login form.

done_testing;