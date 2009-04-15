#!/usr/bin/perl

use warnings;
use strict;

use Networking;

# The general expect timeout.
my $timeout = 30;

use Expect;

# Set to 1 to see what's happening as it happens, but mixed with all
# the other output so it looks awful
$Expect::Log_Stdout = 0;
# Uncomment the two below for debugging
#$Expect::Debug = 3;
#$Expect::Exp_Internal = 1;

# Set this if you are manually testing this script by connecting a
# live client to it.
my $manual = 0;

# POE puts the last client input here for matching
my @last_input='';

# The expect object.
my $exp;

##########
# Expect hepler functions
##########

sub client_not_expect {
    ok( ! $exp->expect($timeout, $_[0] ), $_[1] );
    # print " ^--- $_[1]\n";
    #or die "\n\nExpect of ".$_[0]." failed.\n\n";
};

sub client_expect {
    ok( $exp->expect($timeout, $_[0] ), $_[1] );
    print " ^--- $_[1]\n";
    #or die "\n\nExpect of ".$_[0]." failed.\n\n";
};

sub client_expect_re {
    ok( $exp->expect($timeout, "-re", $_[0] ), $_[1] );
    print " ^--- $_[1]\n";
    #or die "\n\nExpect of ".$_[0]." failed.\n\n";
};

sub client_key_send {
    $exp->send( $_[0] );
    #or die "\n\nSend of ".$_[0]." failed.\n\n";
};

sub client_exit {
    $exp->soft_close();

    $exp->hard_close();
};

#####################
# Launch the server
#####################

my $listener = make_server();

#####################
# Launch the client
#####################

if( ! $manual )
{
    $ENV{TERM} = "vt220";

    $exp = new Expect ();

    $exp->raw_pty(1);

    $exp =
	Expect->spawn("/usr/bin/perl",
		"-MDevel::Cover",
		"/home/rlpowell/programming/cutegirls/client/client.pl",
		@ARGV[1..$#ARGV],
		)
	or die "Cannot spawn client $!\n";

    $exp->log_file( "/tmp/cg-client.out", "w" );
} else {
    $exp = ManualExpect::fake();
}

# Here's where we launch the actual tests
require $ARGV[0];

tests( $listener );

client_exit();
