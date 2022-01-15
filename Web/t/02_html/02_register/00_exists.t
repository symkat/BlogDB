#!/usr/bin/env perl
use Mojo::Base '-signatures';
use BlogDB::Web::Test;

my $t = Test::Mojo::BlogDB->new('BlogDB::Web');

$t->get_ok( '/register')
    ->status_is( 200 )
    ->text_is('title', 'BlogDB - Register');

done_testing;