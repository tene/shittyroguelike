#!/usr/bin/perl

use warnings;
use strict;

use POE qw(Component::Server::TCP);
use POE qw(Filter::Reference);

use Data::Dumper;
use Coro;

use ManualExpect;

use Test::More tests => 12;

# POE variables
my $kernel;
my $heap;

# The general expect timeout.
my $timeout = 20;

# Set this if you are manually testing this script by connecting a
# live client to it.
my $manual = 0;

# POE puts the last client input here for matching
my @last_input='';

# The expect object.
my $exp;

sub client_tcp_send {
    # print "Sending to client ".$heap->{client}.": @_.\n";

    $heap->{client}->put( \@_ );

    $kernel->alarm( cede => time() + 3 );

    cede;
};

sub client_not_expect {
    not_ok( $exp->expect($timeout, $_[0] ), $_[1] );
    #or die "\n\nExpect of ".$_[0]." failed.\n\n";
};

sub client_expect {
    ok( $exp->expect($timeout, $_[0] ), $_[1] );
    #or die "\n\nExpect of ".$_[0]." failed.\n\n";
};

sub client_key_send {
    $exp->send( $_[0] );
    #or die "\n\nSend of ".$_[0]." failed.\n\n";
};

# First argument is test name.  Remaining arguments is stuff to
# compare @last_input against.
sub test_client_tcp {
    cede;

    # print "last input: ".Dumper(\@last_input)."\n";
    # print "expected input: ".Dumper([ @_[1..$#_] ])."\n";

    # NOTE:
    #
    # To make this not error due to Coro issues, we modified lin 476
    # of /usr/share/perl/5.10.0/Test/Builder.pm
    #
    # It used to look like this:
    #
    #     return $self->_try( sub { ref $thing && $thing->isa('UNIVERSAL') } ) ? 1 : 0;
    #
    # We changed it to:
    #
    #     return $self->_try( sub { ref $thing } ) ? 1 : 0;

    is_deeply( [ @last_input ], [ @_[1..$#_] ] , $_[0], );
};

use Expect;

$Expect::Log_Stdout = 0;
#$Expect::Debug = 3;
# You probably want this last one
#$Expect::Exp_Internal = 1;

if( ! $manual )
{
    $ENV{TERM} = "vt100";

    $exp = new Expect ();

    $exp->raw_pty(1);

    $exp =
	Expect->spawn("/usr/bin/perl", "-MDevel::Cover", "/home/rlpowell/programming/cutegirls/client/client.pl") or die "Cannot spawn cliest $!\n";

    $exp->log_file( "/tmp/cg-client.out", "w" );
} else {
    $exp = ManualExpect::fake();
}


async {
    do $ARGV[0];

    exit;
};

POE::Component::Server::TCP->new
(
 Port => 3456,
 ClientInput => \&client_input,
 ClientFilter => POE::Filter::Reference->new('YAML'),
 InlineStates => {
    cede => sub {
	# print "inline cede.\n";
	cede;
    },
 },
 Started => sub {
    # print "starting cede.\n";
    cede;
 },
);

POE::Kernel->run();
exit;

sub client_input {
    # print "in CI 1 .\n";

    my ($session, $input ) = @_[ SESSION, ARG0 ];
    if( ! defined $kernel )
    {
	$kernel = $_[KERNEL];
	$heap = $_[HEAP];
    }

    # DSB
    my ($command, @args) = @$input;

    # print "input: $command, @args\n";

    @last_input = ($command, @args);

    cede;
}

