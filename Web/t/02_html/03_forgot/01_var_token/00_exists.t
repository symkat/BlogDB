#!/usr/bin/env perl
use Mojo::Base '-signatures';
use BlogDB::Web::Test;

my $t = Test::Mojo::BlogDB->new('BlogDB::Web');

# TODO: Create a user account, go through the forgot work flow, arrive at
#       /forgot/token, and verify the title of the page.

$t->get_ok( '/forgot')
    ->status_is( 200 )
    ->text_is('title', 'BlogDB - Forgot Password');

done_testing;