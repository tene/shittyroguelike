#!/usr/bin/perl

use warnings;
use strict;

use POE qw(Component::Client::TCP);
use POE qw(Filter::Reference);

use Data::Dumper;
use Coro;

# POE variables
my $kernel;
my $heap;

# The general expect timeout.
my $timeout = 20;

# POE puts the last server input here for matching
my @inputs=();

sub server_tcp_send {
    # print "Sending to server ".$heap->{server}.": @_.\n";

    $heap->{server}->put( \@_ );

    $kernel->alarm( cede => time() + 3 );

    cede;
};

# First argument is test name.  Remaining arguments is stuff to
# compare $inputs[0] against.
sub server_tcp_test {
    cede;

    # print "input: ".Dumper(\$inputs[0])."\n";
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

    cmp_deeply( $inputs[0], [ @_[1..$#_] ] , $_[0], );

    @inputs = @inputs[1..$#inputs];
};

my $cgserver;

# Close shit down
sub server_exit {
    my $exit = 0;

    if( defined $_[0] )
    {
	$exit = $_[0];
    };

    print "In server exit.\n";

    $cgserver->kill_kill;
    exit $exit;
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

#print "Sleeping for server start.\n";
#sleep 30;
#print "Done sleeping.\n";

async {
        do $ARGV[0];

	server_exit();
};

POE::Component::Client::TCP->new(
	RemoteAddress => "127.0.0.1",
	RemotePort => 3456,
	ServerInput => \&server_input,
	Filter => POE::Filter::Reference->new('YAML'),
	InlineStates => {
	    cede => sub {
		# print "inline cede.\n";
	    cede;
	    },
	},
	Connected => sub {
	    print "connecting cede.\n";

	    if( ! defined $kernel )
	    {
		$kernel = $_[KERNEL];
		$heap = $_[HEAP];
	    }

	    cede;
	},
	ConnectError => sub {
	    $_[KERNEL]->delay( reconnect => 1 );
	},
    );

POE::Kernel->run();
exit;

sub server_input {
    print "in SI 1 .\n";

    my ($session, $input ) = @_[ SESSION, ARG0 ];
    if( ! defined $kernel )
    {
	$kernel = $_[KERNEL];
	$heap = $_[HEAP];
    }

    # DSB
    my ($command, @args) = @$input;

    #print "input: $command, ".Dumper(\@args)."\n";
    print "input: $command, ...\n";

    push @inputs, [ $command, @args ];

    cede;
}

