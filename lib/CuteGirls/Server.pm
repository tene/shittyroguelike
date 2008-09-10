package CuteGirls::Server;

use FindBin::libs;

use POE qw(Wheel::SocketFactory Wheel::ReadWrite
                    Driver::SysRW Filter::Reference);
use Data::Dumper;

use Player;
use Place;
use Place::Thing;

use Perl6::Slurp;
use Perl6::Subs;
use Switch 'Perl6';

my $default_port = 3456;

my $server_session;

my $map;

my $place;

sub new ($self,$mapfile,?$port) {
    $default_port ||= $port;
    $map = slurp '<:utf8', $mapfile;
    $place = Place->new();
    $place->load($map);
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
                    add_player => \&add_player,
                    object_move_rel => \&object_move_rel,
                    player_move_rel => \&player_move_rel,
                    attack => \&attack,
                    drop_item => \&drop_item,
                    remove_object => \&remove_object,
                    change_object => \&change_object,
                    chat => \&chat,
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
         'Filter'     => POE::Filter::Reference->new,
         'InputEvent' => 'input',
         'ErrorEvent' => 'error',
    );
    $heap->{wheel}->put(['new_map', $place]);
    $heap->{wheel}->put(['assign_id', $session->ID]);
}

sub connection_input {
    my ($kernel, $session, $heap, $input) = @_[KERNEL, SESSION, HEAP, ARG0];

    my ($command, @args) = @$input;
    $kernel->post($session, $command, @args);
}

sub add_player {
    my ($kernel, $session, $heap, $id, $username, $symbol, $fg, $bg, $hp) = @_[KERNEL, SESSION, HEAP, ARG0, ARG1, ARG2, ARG3, ARG4, ARG5];
    my ($origin) = grep {(ref $_) eq 'Entrance'} values %{$place->objects};
    my ($x, $y) = ($origin->tile->x, $origin->tile->y);
    print "Adding a new player: $id $symbol $fg $bg $y $x\n";
    $heap->{id} = $id;
    $place->objects->{$id} = Player->new(
            id       => $id,
            username => $username,
            symbol   => $symbol,
            fg       => $fg,
            bg       => $bg,
            tile     => $place->chart->[$y][$x],
            max_hp   => $hp,
            cur_hp   => $hp,
        );
    $place->objects->{$id}->{tile}->vasru(0);
    $kernel->post($server_session, 'broadcast', ['add_player', $id, $username, $symbol, $fg, $bg, $hp, $y, $x]);
}
sub object_move_rel {
    my ($kernel, $session, $heap, $id, $ox, $oy) = @_[KERNEL, SESSION, HEAP, ARG0, ARG1, ARG2];
    my $player = $place->objects->{$id};
    my $dest = $player->get_tile_rel($ox,$oy);

    return unless $dest->vasru;
    $player->tile->leave($player);
    $dest->enter($player);
    $player->tile($dest);

    $kernel->post($server_session, 'broadcast', ['object_move_rel', $id, $ox, $oy]);
}
sub player_move_rel {
    my ($kernel, $session, $heap, $ox, $oy) = @_[KERNEL, SESSION, HEAP, ARG0, ARG1];
    $kernel->call($session, 'object_move_rel', $session->ID, $ox, $oy);
}
sub attack {
    my ($kernel, $session, $heap, $id, $ox, $oy) = @_[KERNEL, SESSION, HEAP, ARG0, ARG1, ARG2];
    my $self = $place->objects->{$session->ID};
    my $other = $place->objects->{$id};
    my $dest = $self->get_tile_rel($ox,$oy);
    return unless $dest == $other->tile;
    print $self->symbol, '→', $other->symbol, "\n";
    $other->cur_hp($other->cur_hp - 11);
    if ($other->alive) {
        $kernel->post($server_session, 'broadcast', ['change_object', $other->id, {'cur_hp'=>$other->cur_hp}]);
    }
    else {
        $kernel->post($server_session, 'broadcast', ['change_object', $other->id, $other->death()]);
    }
}
sub drop_item {
    my ($kernel, $session, $heap, $symbol,$fg,$bg) = @_[KERNEL, SESSION, HEAP, ARG0, ARG1, ARG2];
    my $player = $place->objects->{$heap->{id}};
    my $obj = Place::Thing->new(fg=>$fg,bg=>$bg,symbol=>$symbol);
    $place->objects->{$obj->id} = $obj;
    $kernel->post($server_session,'broadcast',['drop_item',$heap->{id},$obj]);
    $player->tile->enter($obj);
    my $rand = 5+rand(rand(rand(100)));
    $kernel->delay_set('change_object',$rand/2,$obj->id,{'symbol'=>'°','fg'=>'magenta'});
    $kernel->delay_set('remove_object',$rand,$obj->id);
}
sub remove_object {
    my ($kernel, $session, $heap, $id) = @_[KERNEL, SESSION, HEAP, ARG0];
    $place->objects->{$id}->tile->leave($place->objects->{$id});
    delete $place->objects->{$id};
    $kernel->post($server_session, 'broadcast', ['remove_object', $id]);
}
sub change_object {
    my ($kernel, $session, $heap, $id, $changes) = @_[KERNEL, SESSION, HEAP, ARG0, ARG1];
    my $obj = $place->objects->{$id};
    for my $attr (keys %{$changes}) {
        $obj->$attr($changes->{$attr});
    }
    $kernel->post($server_session, 'broadcast', ['change_object', $id, $changes]);
}
sub chat {
    my ($kernel, $session, $heap, $id, $message) = @_[KERNEL, SESSION, HEAP, ARG0, ARG1];
    $kernel->post($server_session, 'broadcast', ['chat', $id, $message]);
}

sub connection_error {
   my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
   return unless defined($place->objects->{$heap->{id}});
   $kernel->post($server_session, 'broadcast', ['remove_object', $heap->{id}]);
   $place->objects->{$heap->{id}}->tile->leave($place->objects->{$heap->{id}});
   delete $place->objects->{$heap->{id}};
}

sub connection_broadcast {
   my ($kernel, $session, $heap, $message) = @_[KERNEL, SESSION, HEAP, ARG0];

   $heap->{wheel}->put($message);
}

1;
