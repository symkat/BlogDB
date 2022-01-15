#!/usr/bin/env perl
use Mojo::Base '-signatures';
use BlogDB::Web::Test;

my $t = Test::Mojo::BlogDB->new('BlogDB::Web');

# Try creating a valid account, ensure it exists in the DB.
$t->post_ok( '/register', form => { 
        username => 'fred',
        email    => 'fred@blog.com',
        password => 'SuperSecure',
        confirm  => 'SuperSecure',
    })->status_is( 302 
    )->code_block( sub {
        is( scalar(@{shift->stash->{errors}}), 0, 'No errors' );
    })->code_block( sub {
        is( shift->app->db->resultset('Person')->search( { username => 'fred'})->count, 1, 'User created.');
    })->get_ok( '/'
    )->code_block( sub {
        is(shift->stash->{person}->username, 'fred', 'Got the fred after login...');
    })->stash_has( { entries => [ ]}, "Blog entry array ref exists.");

# New Session, verify it isn't logged in.
$t = Test::Mojo::BlogDB->new('BlogDB::Web');
$t->get_ok( '/' )->code_block( sub { is(shift->stash->{person}, undef, "Not logged in.") });

# Fill out the forgot password form to get a token.
$t->post_ok( '/forgot', form => { username => 'fred' })
    ->status_is( 200 )
    ->stash_has( { success => 1}, "Finished setting token.")
    ->code_block( sub { 
        my $t = shift;
        ok my $fred = $t->app->db->resultset('Person')->find( { username => 'fred' }), "Found fred in DB.";
        ok my $reset_token = $fred->search_related('password_tokens')->first->token, "Found reset token in DB.";
        $t->stash( { %{$t->stash}, token => $reset_token } )
    });

my $reset_token = $t->stash->{token};

# Use the reset password form to reset the password.
$t->post_ok( "/forgot/$reset_token", form => { 
        reset_token => $reset_token,
        password    => 'NewPassword',
        confirm     => 'NewPassword',
    })->stash_has( { success => 1 });

# New Session, verify it isn't logged in.
$t = Test::Mojo::BlogDB->new('BlogDB::Web');
$t->get_ok( '/' )->code_block( sub { is(shift->stash->{person}, undef, "Not logged in.") });

# Prove the login doesn't work with the old password.
$t->post_ok( '/login', form => { username => 'fred', password => 'SuperSecure'})
    ->get_ok( '/')
    ->code_block( sub { is( shift->stash->{person}, undef, "Old password doesn't work.")});

# Prove the login works with the new password.
$t->post_ok( '/login', form => { username => 'fred', password => 'NewPassword'})
    ->get_ok( '/')
    ->code_block( sub { is( shift->stash->{person}->username, 'fred', "New password does work.")});

done_testing();