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

# Trying to edit the blog as an anonymous user doesn't work.
$t = Test::Mojo::BlogDB->new('BlogDB::Web');

$t->get_ok( "/blog/e/$slug" )->stash_has( { 
    errors => [ 'Login required.' ] 
}, 'Cannot view edit blog page without login.' );

$t->post_ok( "/blog/e/$slug" )->stash_has( { 
    errors => [ 'Login required.' ] 
}, 'Cannot view edit blog page without login.' );

# Trying to edit the blog as a logged in user doesn't work,
# without the can_manage_blogs permission.
$t = Test::Mojo::BlogDB->new('BlogDB::Web');

$t->create_user->get_ok( "/blog/e/$slug" )->stash_has( { 
    errors => [ 'Not Authorized.' ] 
}, 'Cannot view edit blog page without can_manage_blogs.' );

$t->post_ok( "/blog/e/$slug" )->stash_has( { 
    errors => [ 'Not Authorized.' ] 
}, 'Cannot post to edit blog page without can_manage_blogs.' );

# Editing the blog with can_manage_blogs does work.
$t = Test::Mojo::BlogDB->new('BlogDB::Web');

$t->create_user({ can_manage_blogs => 1 })->get_ok( "/blog/e/$slug" )->code_block( sub { 
    ok $t->stash->{blog}, "Have blog object.";
    is $t->stash->{form_title}, 'modFoss', 'Form stash works.';
});

$t->post_ok( "/blog/e/$slug", form => {
    title   => 'modFoss Blog',
    url     => 'http://modfoss.com/',
    rss_url => 'http://modfoss.com/feed',
    tagline => 'Technical Matters under Articles',
    about   => 'Blog Technical, A?',
})->code_block( sub {
    $t->_ss($t->app->db->resultset('Blog')->find( { url => 'https://modfoss.com/'}));
    is $t->_sg, undef, 'Blog cannot be found by the old URL.';
    $t->_ss($t->app->db->resultset('Blog')->find( { url => 'http://modfoss.com/'}));
    ok $t->_sg, 'Blog is found by the new URL now.';
    is $t->_sg->title, 'modFoss Blog', 'The blog updated.';

});

done_testing;