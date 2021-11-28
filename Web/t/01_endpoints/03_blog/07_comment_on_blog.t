#!/usr/bin/env perl
use Mojo::Base '-signatures';
use BlogDB::Web::Test;

# Create and publish the modFoss blog.
my $t = Test::Mojo::BlogDB->new('BlogDB::Web');

my ($blog_id, $slug);
$t->create_user({can_manage_blogs => 1})->post_ok( '/blog/new',  
    form => { url => 'https://modfoss.com/',
})->code_block( sub {
    $blog_id = $t->app->db->resultset('PendingBlog')->find( { url => 'https://modfoss.com/'})->id;
})->post_ok( "/blog/new/$blog_id", form => {
    title   => 'modFoss',
    url     => 'https://modfoss.com/',
    rss_url => 'https://modfoss.com/feed',
    tagline => 'Articles on technical matters.',
    about   => 'A technical blog.'
})->post_ok( "/blog/publish/$blog_id", form => {
})->code_block( sub {
    $slug = $t->app->db->resultset('Blog')->find( { url => 'https://modfoss.com/'})->slug;
});

# User who isn't logged in cannot comment on a blog..
$t = Test::Mojo::BlogDB->new('BlogDB::Web');
$t->post_ok( '/blog/comment', form => { 
    blog_id   => $blog_id,
    message   => 'First Comment',
    rev_pos   => 1,
})->stash_has( { errors => [ 'Login required.']}, 'Login required to post comment.');

# User can post a comment.
# They (or another user) can then reply to comments.
# Create a comment, then reply to it, verify both comments show up.
$t = Test::Mojo::BlogDB->new('BlogDB::Web');
$t->create_user->post_ok( '/blog/comment', form => { 
    blog_id   => $blog_id,
    message   => 'First Comment',
    rev_pos   => 1,
})->code_block( sub {
    my $t = shift;
    $t->_ss($t->app->db->resultset('Message')->find($t->stash->{created_comment_id}));
    ok $t->_sg, 'Got comment object.';
    is $t->_sg->content, 'First Comment', 'Comment object has correct message.';
    $t->_ss( $t->_sg->id );
})->post_ok( '/blog/comment', form => { 
    blog_id   => $blog_id,
    message   => 'Child Comment',
    rev_pos   => 1,
    parent_id => $t->_sg,
})->code_block( sub {
    $t->_ss($t->app->db->resultset('Message')->find($t->_sg));
    ok $t->_sg, 'Got comment object.';
    is $t->_sg->content, 'First Comment', 'Comment object has correct message.';
    $t->_ss( @{$t->_sg->get_children} );
    ok $t->_sg, 'Got comment object\'s child.';
    is $t->_sg->content, 'Child Comment', 'Comment object has correct message.';
});

done_testing;