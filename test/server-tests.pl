#!/usr/bin/perl

use TAP::Harness;

my $pwd = `pwd`;
chomp $pwd;

my $harness = TAP::Harness->new( {
	"verbosity" => 1,
	"exec" => sub {
	    # Do nothing special, yet.
	    my ( $harness, $test_file ) = @_;

	    return [ "$pwd/server-harness.pl", "$test_file" ];
	}
	} );

$harness->runtests(
	"$pwd/server-test-1.pl",
	);

