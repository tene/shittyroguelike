#!/usr/bin/perl

use strict;

use FindBin::libs;
use CuteGirls::Server;

print STDERR "Starting server...\n";

use Getopt::Long;
my $map = "map3";
my $port = 3456;
my $help = '';
my $reset = '';
my $result = GetOptions ("p|port=i" => \$port,    # numeric
                      "m|map=s"   => \$map,      # string
                      "r|reset"  => \$reset,	# flag
		      "h|help|?" => \$help,
);

if( $help )
{
    print qq{
	
-p|--port		Specify the port to listen on.
-m|--map		Specify the map file to use
-r|--reset		Clean out the player list

};
    exit 1
};

my $server = CuteGirls::Server->new( $map, $port, $reset );
POE::Kernel->run();

exit;
