#!/usr/bin/env perl
use Mojo::Base '-signatures';
use BlogDB::Web::Test;

my $t = Test::Mojo::BlogDB->new('BlogDB::Web');

# Post a new blog as a logged in user, ensure that it exists, make sure that the submitter id matches.
$t->create_user->post_ok( '/blog/new', 
    form => {
        url => 'https://modfoss.com/',        
    })->code_block( sub { 
        my ( $t ) = @_;
        $t->_ss($t->app->db->resultset('PendingBlog')->find( { url => 'https://modfoss.com/'}));
        ok $t->_sg, "Created blog entry.";
        is $t->_sg->submitter_id, $t->stash->{person}->id, 'Owned by the current user.';
        is $t->_sg->edit_token, undef, 'No edit token for a user-submitted blog.';
    });

my $blog_id = $t->_sg->id;

# New Session.
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

done_testing;