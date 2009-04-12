#!/usr/bin/perl

use TAP::Harness;

`rm -rf cover_db/`;

my $pwd = `pwd`;
chomp $pwd;

my $harness = TAP::Harness->new( {
	"verbosity" => 1,
	"exec" => sub {
	    # Deal with special CLI arg tests.
	    my ( $harness, $test_file ) = @_;

	    # SPECIAL CASE.  Test 4 tests command-line based login
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

$harness->runtests( 
	glob("$pwd/client-test-*.pl")
	);

print `cover`;
