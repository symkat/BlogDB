#!/usr/bin/env perl
#
# Post a new blog without any user account, and then edit the blog.
# Make sure the edit_token functionality is being used. 
use Mojo::Base '-signatures';
use BlogDB::Web::Test;

my $t = Test::Mojo::BlogDB->new('BlogDB::Web');

$t->post_ok( '/blog/new', 
    form => {
        url => 'https://modfoss.com/',        
    })->code_block( sub { 
        my ( $t ) = @_;
        $t->_ss($t->app->db->resultset('PendingBlog')->find( { url => 'https://modfoss.com/'}));
        ok $t->_sg, "Created blog entry.";
        ok $t->_sg->edit_token, 'Edit token exists';
    });

my $blog_id = $t->_sg->id;

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
    is $t->_sg->title, 'modFoss', 'Title updated.';
    is $t->_sg->url, 'https://modfoss.com/', 'URL updated.';
    is $t->_sg->rss_url , 'https://modfoss.com/feed', 'RSS URL updated.';
    is $t->_sg->tagline , 'Articles on technical matters.', 'Tagline updated.';
    is $t->_sg->about , 'A technical blog.', 'About updated.';
})->stash_has( { authorization => [ 'token' ] } );

done_testing;