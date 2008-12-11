#!/usr/bin/perl

use TAP::Harness;

my $pwd = `pwd`;
chomp $pwd;

my $harness = TAP::Harness->new( {
	"verbosity" => 1,
	"exec" => sub {
	    # Deal with special CLI arg tests.
	    my ( $harness, $test_file ) = @_;

	    if( $test_file =~ m/-4.pl/ )
	    {
		return [ "$pwd/client-harness.pl", "$test_file",
		"--server", "localhost",
		"--user", "rlpowell" ];
	    } else {
		return [ "$pwd/client-harness.pl", "$test_file" ];
	    }
	}
	} );

$harness->runtests( "$pwd/client-test-1.pl",
	"$pwd/client-test-2.pl",
	"$pwd/client-test-3.pl",
	"$pwd/client-test-4.pl",
	);

