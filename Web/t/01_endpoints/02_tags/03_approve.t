#!/usr/bin/env perl
use Mojo::Base '-signatures';
use BlogDB::Web::Test;

my $t = Test::Mojo::BlogDB->new('BlogDB::Web');

# Create a user and a tag.
$t->create_user->create_tag( 'first' )->code_block( sub {
    my $t = shift;
    $t->_ss( $t->app->db->resultset('PendingTag')->search({name => 'first'})->first);
    ok $t->_sg, "Found tag";
    is $t->_sg->name, 'first', "Tag named correctly.";
    is $t->_sg->vote_score, 0, "Vote score = 0";
})->create_tag( 'second' )->create_tag( 'third');

# The user cannot approve the tag.
$t->post_ok( '/tags/approve', form => { tag => 'first'})
    ->code_block( sub {
        my $t = shift;
        $t->_ss( $t->app->db->resultset('Tag')->search({name => 'first'})->first);
        is $t->_sg, undef, "The tag has not been approved.";
     })
     ->stash_has( { errors => [ 'Not authorized.' ] }, 'Rejected error message.');

# A user who is not logged in cannot approve the tag.
$t = Test::Mojo::BlogDB->new('BlogDB::Web')
    ->post_ok( '/tags/approve', form => { tag => 'second'})
    ->code_block( sub {
        my $t = shift;
        $t->_ss( $t->app->db->resultset('Tag')->search({name => 'second'})->first);
        is $t->_sg, undef, "The tag has not been approved.";
     });

# A user with the setting can_add_tags can approve the tag.
$t->create_user( { can_manage_tags => 1 } )
    ->post_ok( '/tags/approve', form => { tag => 'second'} )
    ->code_block( sub {
        is( shift->stash->{person}->setting('can_manage_tags'), 1, "User has permission.");
     })
     ->code_block( sub {
        my $t = shift;
        $t->_ss( $t->app->db->resultset('Tag')->search({name => 'second'})->first);
        ok $t->_sg, "The tag exists in the Tag list.";
        $t->_ss( $t->app->db->resultset('PendingTag')->search({name => 'second'})->first);
        is $t->_sg, undef, "The tag has been deleted from the PendingTag list.";
     });

done_testing;