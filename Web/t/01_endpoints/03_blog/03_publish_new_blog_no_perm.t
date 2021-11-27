#!/usr/bin/env perl
# Test to make sure that a normal user (w/o can_manage_blogs) cannot approve a blog.
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

# Update the blog as the same user.
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
})->stash_has( { authorization => [ 'submitter' ] } );

# Now we try to publish the blog, it should fail for no user account.
$t->post_ok( "/blog/publish/$blog_id", form => {})
    ->stash_has( { errors => [ 'Not Authorized.' ] });



done_testing;