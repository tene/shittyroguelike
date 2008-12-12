#!/usr/bin/perl

use warnings;
use strict;

use Data::Dumper;

use Networking;

# The general expect timeout.
my $timeout = 20;

my $cgserver;

# Close shit down
sub server_exit {
    my $exit = 0;

    if( defined $_[0] )
    {
	$exit = $_[0];
    };

    $cgserver->kill_kill;
    #exit $exit;
};

#use Expect;
#Expect->spawn("/usr/bin/perl", "-MDevel::Cover", "/home/rlpowell/programming/cutegirls/server/server.pl") or die "Cannot spawn server $!\n";
use IPC::Run qw( run timeout start );
my $in;
my $out;

$cgserver = start [ "/usr/bin/perl", "-MDevel::Cover",
   "/home/rlpowell/programming/cutegirls/server/server.pl",
   "--reset" ], \$in, \$out ;

$SIG{INT} = sub {
    print "Caught INT.\n";
    server_exit( 1 );
};

require $ARGV[0];

tests( $cgserver );

server_exit();
