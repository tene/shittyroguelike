#!/usr/bin/perl

use TAP::Harness;

my $pwd = `pwd`;
chomp $pwd;

my $harness = TAP::Harness->new( {
	"verbosity" => 1,
	"exec" => [ "$pwd/client-harness.pl" ],
	} );

$harness->runtests( "$pwd/client-test-1.pl" );
