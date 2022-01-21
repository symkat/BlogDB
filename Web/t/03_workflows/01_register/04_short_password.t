#!/usr/bin/env perl
#==
# Confirm a too-short password results in an error.
#==
use Mojo::Base '-signatures';
use BlogDB::Web::Test;

my $t = Test::Mojo::BlogDB->new('BlogDB::Web');

# Submit the form and confirm we are told the errors and not allowed to proceed.
$t->post_ok( '/register', form => { 
        username => 'fred',
        email    => 'fred@blog.com',
        password => 'Short',
        confirm  => 'Short',
    })->status_is( 200 )
    ->content_like( qr|There were errors with your request| )
    ->content_like( qr|Password must be at least 7 chars| );

done_testing();