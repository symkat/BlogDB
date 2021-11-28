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

# View the blog as an anonymous user.
$t = Test::Mojo::BlogDB->new('BlogDB::Web');

$t->get_ok( "/blog/v/$slug" )->code_block( sub {
    my $t = shift;
    ok $t->stash->{blog};
    is $t->stash->{person}, undef, 'No person object for anon.';
    is $t->stash->{blog}->title, 'modFoss', 'Blog object found.';
});

# View the blog as a logged in user.
$t = Test::Mojo::BlogDB->new('BlogDB::Web');

$t->create_user->get_ok( "/blog/v/$slug" )->code_block( sub {
    my $t = shift;
    ok $t->stash->{blog};
    ok $t->stash->{person}, 'Person object for logged in user.';
    is $t->stash->{blog}->title, 'modFoss', 'Blog object found.';
});

done_testing;