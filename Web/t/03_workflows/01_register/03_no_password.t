#!/usr/bin/env perl
#==
# Confirm a lack of password field results in an error.
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

# Submit the form and confirm we are told the errors and not allowed to proceed.
$t->post_ok( '/register', form => { 
        username => 'fred',
        email    => 'fred@blog.com',
        confirm  => 'NotSuperSecure',
    })->status_is( 200 )
    ->content_like( qr|There were errors with your request| )
    ->content_like( qr|Password is required| );

done_testing();