#!/usr/bin/env perl
use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use Test::Postgresql58;
use DBI;

my $t = Test::Mojo->new('BlogDB::Web');

$t->get_ok( '/' );

our $pgsql = Test::Postgresql58->new()
    or BAILOUT( "PSQL Error: " . $Test::Postgresql58::errstr );

load_psql_file("/home/symkat/Code/BlogDB/DB/etc/schema.sql");

# Create an account.
$t->post_ok( '/register', form => { 
        username => 'fred',
        email    => 'fred@blog.com',
        password => 'SuperSecure',
        confirm  => 'SuperSecure',
    })->status_is( 200 );

# Login works and redirects the user.
$t->post_ok( '/login', form => {
        username => 'fred',
        password => 'SuperSecure',
        confirm  => 'SuperSecure',
        return   => '/',
    })->status_is( 302 );

# Login without account throws an error
$t->post_ok( '/login', form => {
        username => 'james',
        password => 'NoPassword',
        confirm  => 'NoPassword',
        return   => '/',
    })->status_is( 500 );

done_testing();

sub load_psql_file {
    my ( $file ) = @_;

    open my $lf, "<", $file
        or die "Failed to open $file for reading: $!";
    my $content;
    while ( defined( my $line = <$lf> ) ) {
        next unless $line !~ /^\s*--/;
        $content .= $line;
    }
    close $lf;

    my $dbh = DBI->connect( $pgsql->dsn );
    for my $command ( split( /;/, $content ) ) {
        next if $command =~ /^\s*$/;
        $dbh->do( $command )
            or BAIL_OUT( "PSQL Error($file): $command: " . $dbh->errstr);
    }
    undef $dbh;
}
