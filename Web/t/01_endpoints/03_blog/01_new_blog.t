#!/usr/bin/env perl
use Mojo::Base '-signatures';
use BlogDB::Web::Test;

my $t = Test::Mojo::BlogDB->new('BlogDB::Web');

# Post a new blog as a logged in user, ensure that it exists,
# make sure that the submitter id matches.
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

# Post a new blog as an anonymous user, ensure that it exists,
# and an edit token has been created for it.
Test::Mojo::BlogDB->new('BlogDB::Web')->post_ok( '/blog/new', 
    form => {
        url => 'https://symkat.com/',        
    })->code_block( sub { 
        my ( $t ) = @_;
        $t->_ss($t->app->db->resultset('PendingBlog')->find( { url => 'https://symkat.com/'}));
        ok $t->_sg, "Created blog entry.";
        is $t->_sg->submitter_id, undef, 'No submitter id for anonymous submitted blog.';
        ok $t->_sg->edit_token, 'Edit token for a anonymous-submitted blog exists.';
    });

done_testing;