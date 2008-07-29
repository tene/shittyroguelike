#!/usr/bin/perl

use strict;

use FindBin::libs;

use POE qw(Wheel::SocketFactory);
use Switch 'Perl6';
use Perl6::Subs;

#===============================================================================
package CuteGirls::Server;

use FindBin::libs;

use POE qw(Wheel::SocketFactory Wheel::ReadWrite
                    Driver::SysRW Filter::Line);
use Data::Dumper;

use Server::Player;

my $default_port = 3456;

my $server_session;

my %players;

sub new (?$port) {
    $default_port ||= $port;
    $server_session = POE::Session->create(
        inline_states=> {
            _start => \&poe_start,
            accepted => \&poe_accepted,
            error    => \&poe_error,
            broadcast => \&server_broadcast,
        },
    );
    $server_session;
}

sub poe_start {
    my ($heap) = @_[HEAP,];
    $heap->{listener} = POE::Wheel::SocketFactory->new
        ( SuccessEvent => 'accepted',
          FailureEvent => 'error',
          BindPort     => $default_port,
          Reuse        => 'yes',
        );
    $heap->{connections} = [];
}

# Start a session to handle successfully connected clients.
sub poe_accepted {
    my ($heap, $socket, $addr, $port) = @_[HEAP,ARG0,ARG1,ARG2];
    push @{$heap->{connections}},   POE::Session->create(
                                        inline_states=> {
                                            _start => \&connection_start,
                                            input  => \&connection_input,
                                            error  => \&connection_error,
                                            broadcast => \&connection_broadcast,
                                        },
                                        args => [ $socket, $addr, $port],
                                    );
}

# Upon error, log the error and stop the server.  Client sessions may
# still be running, and the process will continue until they
# gracefully exit.
sub poe_error {
  warn "CuteGirls::Server encountered $_[ARG0] error $_[ARG1]: $_[ARG2]\n";
  delete $_[HEAP]->{listener};
}


sub server_broadcast {
   my ($kernel, $session, $heap, $message) = @_[KERNEL, SESSION, HEAP, ARG0];

   for my $conn (@{$heap->{connections}}) {
       $kernel->post($conn,'broadcast',$message);
   }
}

sub connection_start {
    my ($kernel, $session, $heap, $handle, $peer_addr, $peer_port) =
     @_[KERNEL, SESSION, HEAP, ARG0, ARG1, ARG2];
 
    print STDERR "Session ", $session->ID, " - received connection\n";
 
                                         # start reading and writing
    $heap->{wheel} = POE::Wheel::ReadWrite->new(
         'Handle'     => $handle,
         'Driver'     => POE::Driver::SysRW->new,
         'Filter'     => POE::Filter::Line->new,
         'InputEvent' => 'input',
         'ErrorEvent' => 'error',
    );
    # hello, world!\n
    #$heap->{wheel}->put('Connected to server', '', '');
    $heap->{wheel}->put('assign_id ' . $session->ID);
    while ( my ($id, $player)  = each %players) {
        print $player->id(), "\n";
        $heap->{wheel}->put('add_player ' . join(' ', (
                    $player->id(),
                    $player->symbol(),
                    $player->fg(),
                    $player->bg(),
                    $player->y(),
                    $player->x(),
                )) . "\n");
    }
}

sub connection_input {
    my ($kernel, $session, $heap, $input) = @_[KERNEL, SESSION, HEAP, ARG0];

    my ($command, @args) = split / /, $input;
    if ($command eq 'add_player') {
        print "Adding a new player: $input\n";
        my ($id, $symbol, $fg, $bg, $y, $x) = @args;
        $heap->{id} = $id;
        $players{$id} = Server::Player->new(
                id     => $id,
                symbol => $symbol,
                fg     => $fg,
                bg     => $bg,
                y      => $y,
                x      => $x,
            );
        $kernel->post($server_session, 'broadcast', $input);
    }
    elsif ($command eq 'player_move_rel') {
        my ($id, $x, $y) = @args;
        my $player = $players{$id};
        $player->x($player->{x} + $x);
        $player->y($player->{y} + $y);
        $kernel->post($server_session, 'broadcast', $input);
    }
    elsif ($command eq 'remove_player') {
        my ($id) = @args;
        delete $players{$id};
        $kernel->post($server_session, 'broadcast', $input);
    }
    else {
        $kernel->post($server_session, 'broadcast', $input);
    }
}

sub connection_error {
   my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
   return unless defined($players{$heap->{id}});
   $kernel->post($server_session, 'broadcast', "remove_player $heap->{id}");
   delete $players{$heap->{id}};
}

sub connection_broadcast {
   my ($kernel, $session, $heap, $message) = @_[KERNEL, SESSION, HEAP, ARG0];

   $heap->{wheel}->put($message);
}


#===============================================================================
package main;

print STDERR "Starting server...\n";

my $server = CuteGirls::Server->new();
POE::Kernel->run();

exit;
