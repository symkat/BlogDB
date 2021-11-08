package BlogDB::Web::Test;
use Import::Into;
use Test::More;
use Test::Deep;
use Test::Mojo;
use Test::Postgresql58;

push our @ISA, qw( Exporter );
push our @EXPORT, qw(  );

sub import {
    shift->export_to_level(1);
    my $target = caller;

    Mojo::Base->import::into($target, '-strict');
    warnings  ->import::into($target);
    strict    ->import::into($target);
    Test::More->import::into($target);
    Test::Deep->import::into($target);
    Test::Mojo->import::into($target);
}

our $pgsql = Test::Postgresql58->new()
    or BAILOUT( "PSQL Error: " . $Test::Postgresql58::errstr );

load_psql_file("/home/symkat/Code/BlogDB/DB/etc/schema.sql");

$ENV{BLOGDB_TESTMODE} = 1;
$ENV{BLOGDB_DSN}      = $pgsql->dsn;

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

1;
