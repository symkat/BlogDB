#!/usr/bin/env perl
use Mojo::Base '-signatures';
use BlogDB::Web::Test;

my $t = Test::Mojo::BlogDB->new('BlogDB::Web');

# Post a new blog as a logged in user.
$t->create_user->post_ok( '/blog/new', 
    form => {
        url => 'https://modfoss.com/',        
    })->code_block( sub { 
        my ( $t ) = @_;
        $t->_ss($t->app->db->resultset('PendingBlog')->find( { url => 'https://modfoss.com/'}));
        ok $t->_sg, "Created blog entry.";
    });

my $blog_id = $t->_sg->id;

# New Session, update the blog as a can_manage_blogs user..
$t = Test::Mojo::BlogDB->new('BlogDB::Web');

$t->create_user({ can_manage_blogs => 1 })->post_ok( "/blog/new/$blog_id", form => {
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
})->stash_has( { authorization => [ 'setting:can_manage_blogs' ] } );

# Now we publish the blog, we're still in the user account with can_manage_blogs
$t->post_ok( "/blog/publish/$blog_id", form => {})
    ->code_block( sub { 
    my ( $t ) = @_;
    $t->_ss($t->app->db->resultset('Blog')->find( { url => 'https://modfoss.com/'}));
    ok $t->_sg, "Found published blog";
    is $t->_sg->title, 'modFoss', 'Blog has correct title.';


    $t->_ss($t->app->db->resultset('PendingBlog')->find( { url => 'https://modfoss.com/'}));
    is $t->_sg, undef, "Blog has been deleted from PendingBlogs.";
});

done_testing;