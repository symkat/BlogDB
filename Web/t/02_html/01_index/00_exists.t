#!/usr/bin/env perl
use Mojo::Base '-signatures';
use BlogDB::Web::Test;

my $t = Test::Mojo::BlogDB->new('BlogDB::Web');

$t->get_ok( '/')
    ->status_is( 200 )
    ->text_is('title', 'BlogDB - Homepage');

done_testing;