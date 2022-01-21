#!/usr/bin/env perl
#==
# Confirm mismatched passwords on the registration don't work.
#==
use Mojo::Base '-signatures';
use BlogDB::Web::Test;

my $t = Test::Mojo::BlogDB->new('BlogDB::Web');

# Submit the form and confirm we are told the errors and not allowed to proceed.
$t->post_ok( '/register', form => { 
        username => 'fred',
        email    => 'fred@blog.com',
        password => 'SuperSecure',
        confirm  => 'NotSuperSecure',
    })->status_is( 200 )
    ->content_like( qr|There were errors with your request| )
    ->content_like( qr|Password &amp; Confirmation must match| );

done_testing();