#!/usr/bin/env perl
use Mojo::Base '-signatures';
use BlogDB::Web::Test;

my $t = Test::Mojo::BlogDB->new('BlogDB::Web');

# Suggesting a tag without a user account will not work.
$t->post_ok( '/tags/suggest', form => {
    tag => 'foo',        
})->stash_has( { errors => [ 'Login required.' ]}, 'Prompt for login.');

# Suggesting a tag with a user account will work, the tag will be in the DB in PendingTag.
$t->create_user->post_ok( '/tags/suggest', form => {
    tag => 'foo',        
})->code_block( sub { 
    my ( $t ) = @_;
    $t->_ss( $t->app->db->resultset('PendingTag')->search( { name => 'foo'})->first);
    ok $t->_sg, "The PendingTag was created.";
    is $t->_sg->name, 'foo', "Pending tag named correctly.";
    is $t->_sg->is_adult, 0, 'Tags are not adult by default.';
})->status_is( 302, "Redirect after tag add." )
->post_ok( '/tags/suggest', form => {
    tag => 'foo',
})->stash_has( { errors => [ 'There is already a pending tag with that name.']},
    'Duplicate tag results in error'
)->status_is( 200, "Stay on page during an error." );

# Suggesting the same tag again will result in an error because the tag already exists.
$t->post_ok( '/tags/suggest', form => {
    tag => '9foo',
})->stash_has( { errors => [ 'Tag names must start with a letter, and may only contain letters and numbers.']},
    'Tags starting with numbers result in errors.'
)->status_is( 200, "Stay on page during an error." );

# Suggesting a tag that's an adult tag will make one with is_adult = true
$t->post_ok( '/tags/suggest', form => {
    tag      => 'adult_tag', 
    is_adult => 1,       
})->code_block( sub { 
    my ( $t ) = @_;
    $t->_ss( $t->app->db->resultset('PendingTag')->search( { name => 'adult_tag'})->first);
    ok $t->_sg, "The PendingTag was created.";
    is $t->_sg->name, 'adult_tag', "Pending tag named correctly.";
    is $t->_sg->is_adult, 1, 'Tag is set as an adult tag.';
})->status_is( 302, "Redirect after tag add." );

done_testing();