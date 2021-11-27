#!/usr/bin/env perl
use Mojo::Base '-signatures';
use BlogDB::Web::Test;

my $t = Test::Mojo::BlogDB->new('BlogDB::Web');


# Create a tag, it should have no votes at first.
$t->create_user->create_tag( 'first' )->code_block( sub {
    my $t = shift;
    $t->_ss( $t->app->db->resultset('PendingTag')->search({name => 'first'})->first);
    ok $t->_sg, "Found tag";
    is $t->_sg->name, 'first', "Tag named correctly.";
    is $t->_sg->vote_score, 0, "Vote score = 0";
});

# Upvote them!
$t->post_ok( '/tags/vote', form => {
    tag => 'first'
})->code_block( sub {
    my $t = shift;
    $t->_ss( $t->app->db->resultset('PendingTag')->search({name => 'first'})->first);
    ok $t->_sg, "Found tag";
    is $t->_sg->name, 'first', "Tag named correctly.";
    is $t->_sg->vote_score, 1, "Vote score = 1";
});

# Upvote them again to undo it! 
$t->post_ok( '/tags/vote', form => {
    tag => 'first'
})->code_block( sub {
    my $t = shift;
    $t->_ss( $t->app->db->resultset('PendingTag')->search({name => 'first'})->first);
    ok $t->_sg, "Found tag";
    is $t->_sg->name, 'first', "Tag named correctly.";
    is $t->_sg->vote_score, 0, "Vote score = 0";
});

# Make three new users and upvote it, then check the vote count.
$t = Test::Mojo::BlogDB->new('BlogDB::Web')
    ->create_user
    ->post_ok( '/tags/vote', form => { tag => 'first'});

$t = Test::Mojo::BlogDB->new('BlogDB::Web')
    ->create_user
    ->post_ok( '/tags/vote', form => { tag => 'first'});

$t = Test::Mojo::BlogDB->new('BlogDB::Web')
    ->create_user
    ->post_ok( '/tags/vote', form => { tag => 'first'})
    ->code_block( sub {
        my $t = shift;
        $t->_ss( $t->app->db->resultset('PendingTag')->search({name => 'first'})->first);
        ok $t->_sg, "Found tag";
        is $t->_sg->name, 'first', "Tag named correctly.";
        is $t->_sg->vote_score, 3, "Vote score = 3";
    });

# Voting on a tag without a user account will not work.
$t = Test::Mojo::BlogDB->new('BlogDB::Web')
    ->post_ok( '/tags/vote', form => { tag => 'first'})
    ->stash_has( { errors => [ 'Login required.' ] }, 'Need user account to vote.' )
    ->code_block( sub {
        my $t = shift;
        $t->_ss( $t->app->db->resultset('PendingTag')->search({name => 'first'})->first);
        ok $t->_sg, "Found tag";
        is $t->_sg->name, 'first', "Tag named correctly.";
        is $t->_sg->vote_score, 3, "Same vote count after unauthed vote attempt.";
    });


done_testing;