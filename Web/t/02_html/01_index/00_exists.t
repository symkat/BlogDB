#!/usr/bin/env perl
#==
# Test to ensure / exists and has the correct title.
#==
use Mojo::Base '-signatures';
use BlogDB::Web::Test;

my $t = Test::Mojo::BlogDB->new('BlogDB::Web');

$t->get_ok( '/')
    ->status_is( 200 )
    ->text_is('title', 'BlogDB - Homepage');

done_testing;