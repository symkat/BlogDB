#!/usr/bin/env perl
# Test that a new blog submitted by an anonymous user cannot be edited by a
# different anonymous user.
use Mojo::Base '-signatures';
use BlogDB::Web::Test;

my $t = Test::Mojo::BlogDB->new('BlogDB::Web');

# Post a new blog entry.
$t->post_ok( '/blog/new', 
    form => {
        url => 'https://modfoss.com/',        
    })->code_block( sub { 
        my ( $t ) = @_;
        $t->_ss($t->app->db->resultset('PendingBlog')->find( { url => 'https://modfoss.com/'}));
        ok $t->_sg, "Created blog entry.";
    });

my $blog_id = $t->_sg->id;

# New Session.
$t = Test::Mojo::BlogDB->new('BlogDB::Web');

$t->post_ok( "/blog/new/$blog_id", form => {
    title   => 'modFoss',
    url     => 'https://modfoss.com/',
    rss_url => 'https://modfoss.com/feed',
    tagline => 'Articles on technical matters.',
    about   => 'A technical blog.'
})->code_block( sub { 
    my ( $t ) = @_;
    $t->_ss($t->app->db->resultset('PendingBlog')->find( { url => 'https://modfoss.com/'}));
    ok $t->_sg, "Found blog entry";
    is $t->_sg->title, undef, 'Title still the same';
    is $t->_sg->url, 'https://modfoss.com/', 'URL the same.';
    is $t->_sg->rss_url , undef, 'RSS URL still the same.';
    is $t->_sg->tagline , undef, 'Tagline still the same.';
    is $t->_sg->about , undef, 'About still the same.';
})->stash_has( { errors => [ 'Not Authorized.' ] } );

done_testing;