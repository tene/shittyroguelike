#!/usr/bin/perl

use strict;

use FindBin::libs;
use CuteGirls::Server;

print STDERR "Starting server...\n";

my $server = CuteGirls::Server->new($ARGV[0] || 'map3');
POE::Kernel->run();

exit;
