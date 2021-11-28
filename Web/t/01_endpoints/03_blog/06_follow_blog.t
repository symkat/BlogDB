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

# User who isn't logged in cannot follow a blog.
$t = Test::Mojo::BlogDB->new('BlogDB::Web');
$t->post_ok( '/blog/follow', form => { blog_id => $blog_id })
    ->stash_has( { errors => [ 'Login required.']}, 'Login required to follow blogs.');

# Regular user can follow a blog.
$t = Test::Mojo::BlogDB->new('BlogDB::Web');
$t->create_user->post_ok( '/blog/follow', form => { blog_id => $blog_id })
    ->code_block( sub { 
        my $t = shift;
        my $blogs = $t->stash->{person}->get_followed_blogs;
        is $blogs->[0]->id, $blog_id, "A logged in user can follow a blog.";
    });

done_testing;