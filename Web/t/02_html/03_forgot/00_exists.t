#!/usr/bin/env perl
#==
# Test to ensure /forgot exists.
#==
use Mojo::Base '-signatures';
use BlogDB::Web::Test;

my $t = Test::Mojo::BlogDB->new('BlogDB::Web');

$t->get_ok( '/forgot')
    ->status_is( 200 )
    ->text_is('title', 'BlogDB - Forgot Password');

done_testing;