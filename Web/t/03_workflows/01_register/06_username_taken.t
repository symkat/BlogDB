#!/usr/bin/env perl
#==
# Confirm a user cannot register an already-registered username.
#==
use Mojo::Base '-signatures';
use BlogDB::Web::Test;

my $t = Test::Mojo::BlogDB->new('BlogDB::Web');

# Register a valid user account for fred.
$t->post_ok( '/register', form => { 
        username => 'fred',
        email    => 'fred@blog.com',
        password => 'SuperSecure',
        confirm  => 'SuperSecure',
    })->status_is( 302 );

# New Session
$t = Test::Mojo::BlogDB->new('BlogDB::Web');

# Submit the form and confirm we are told the errors and not allowed to proceed.
$t->post_ok( '/register', form => { 
        username => 'fred',
        email    => 'fred.two@blog.com',
        password => 'SuperSecure',
        confirm  => 'SuperSecure',
    })->status_is( 200 )
    ->content_like( qr|There were errors with your request| )
    ->content_like( qr|This username is already in use| );

done_testing();