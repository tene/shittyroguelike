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
my $players;
my $races = {
    giant => defstats('^',m=>10,o=>10,l=>-5,e=>5,sc=>-10,pr=>-5,ph=>-5,so=>-10),
    ent => defstats('Ψ',m=>10,o=>15,l=>-10,e=>-5,sc=>15,pr=>-5,ph=>-5,so=>-10),
    human => defstats('@'),
    elf => defstats('λ',m=>-2,o=>-5,l=>5,e=>15,sc=>5,pr=>5,ph=>5,so=>-5),
    gnome => defstats('¤',m=>-5,o=>-10,l=>8,e=>8,sc=>10,pr=>-5,ph=>-5,so=>5),
    pixie => defstats('`',m=>-10,o=>-10,l=>18,e=>10,sc=>15,pr=>-6,ph=>-6,so=>10),
    gremlin => defstats(',',m=>-9,o=>-8,l=>10,sc=>10,pr=>5,ph=>3,so=>-10),
};

sub defstats ($sym,+$m,+$o,+$l,+$e,+$sc,+$pr,+$ph,+$so) {
    return {
        symbol => $sym,
        muscle => $m||0,
        organs=> $o||0,
        limbs => $l||0,
        eyes => $e||0,
        scholarly => $sc||0,
        practical => $ph||0,
        physical => $ph||0,
        social => $so||0,
    };
}

sub scaled_logistic ($value, $divisor) {
    return 1/(1+exp(- $value/$divisor));
}

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
                    login => \&login,
                    register => \&register,
                    add_player => \&add_player,
                    tick => \&tick,
                    act => \&act,
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
         'Filter'     => POE::Filter::Reference->new('YAML'),
         'InputEvent' => 'input',
         'ErrorEvent' => 'error',
    );
}

sub connection_input {
    my ($kernel, $session, $heap, $input) = @_[KERNEL, SESSION, HEAP, ARG0];
    my ($command, @args) = @$input;
    $kernel->post($session, $command, @args);
}

sub login {
    my ($kernel, $session, $heap, $username) = @_[KERNEL, SESSION, HEAP, ARG0];
    if (defined $players->{$username}) {
        $heap->{wheel}->put(['new_map', $place]);
        $heap->{wheel}->put(['assign_id', $session->ID]);
    }
    else {
        send_create_form($heap->{wheel});
    }
}

sub send_create_form {
    my $wheel = shift;
    $wheel->put(['create_player','create new character',['Eris','Burn Shit','Cthulhu'],[qw(red green yellow blue magenta cyan white)],[keys %$races]]);
}

sub register {
    my ($kernel, $session, $heap, $username, $race, $god, $color) = @_[KERNEL, SESSION, HEAP, ARG0, ARG1, ARG2, ARG3];
    my $symbol = $races->{$race}->{symbol};
    if (defined $players->{$username}) {
        send_create_form($heap->{wheel});
    }
    else {
        $username ||= 'nobody';
        $symbol ||= substr $username,0,1;
        $color ||= 'red';
        $players->{$username} = {race=>$race,god=>$god,color=>$color};
        $heap->{wheel}->put(['new_map', $place]);
        $heap->{wheel}->put(['assign_id', $session->ID]);
    }
}

sub add_player {
    my ($kernel, $session, $heap, $id, $username) = @_[KERNEL, SESSION, HEAP, ARG0, ARG1];
    my $fg = $players->{$username}->{color};
    my $bg = 'black';
    my $race = $races->{$players->{$username}->{race}};
    my $symbol = $race->{symbol};
    my $hp = ($race->{organs} + 13) * 10;
    my $god = $players->{$username}->{god};
    $kernel->post($server_session, 'broadcast', ['announce', "$username, a loyal follower of $god, has arrived."]);
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
            place    => $place,
            map {$_ => 13 + $race->{$_} } qw/muscle organs limbs eyes scholarly practical physical social/,
        );
    $place->objects->{$id}->{tile}->vasru(0);
    $kernel->post($server_session, 'broadcast', ['add_player', $id, $place->objects->{$id}->to_hash, $y, $x]);
    $kernel->delay_set('tick',rand() + scaled_logistic($race->{limbs},20));
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
    my $self = $place->objects->{$session->ID};
    push @{$self->{actions}}, ['move',$ox,$oy];
    unless (@{$self->{actions}} > 1) {
        $kernel->delay_set('act',scaled_logistic(13-$self->limbs,5)/4);
    }
}
sub tick {
    my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
    my $self = $place->objects->{$session->ID};
    return unless $self;
    if ($self->cur_hp < $self->max_hp) {
        my $next = int($self->cur_hp + $self->organs/4 + $self->physical/2 + rand(2));
        $self->cur_hp(($next > $self->max_hp) ? $self->max_hp : $next );
        $kernel->post($server_session, 'broadcast', ['change_object', $self->id, {'cur_hp'=>$self->cur_hp}]);
    }
    $kernel->delay_set('tick',rand() + 20/$self->limbs);
}
sub act {
    my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
    my $self = $place->objects->{$session->ID};
    return unless $self;
    my ($act, @args) = @{shift @{$self->{actions}}};
    if ($act eq 'move') {
        $kernel->call($session, 'object_move_rel', $session->ID, @args);
    }
    if (@{$self->{actions}} > 0) {
        $kernel->delay_set('act',scaled_logistic(13-$self->limbs,5)/4);
    }
}
sub attack {
    my ($kernel, $session, $heap, $id, $ox, $oy) = @_[KERNEL, SESSION, HEAP, ARG0, ARG1, ARG2];
    my $self = $place->objects->{$session->ID};
    my $selfname = $self->username;
    my $other = $place->objects->{$id};
    my $othername = $other->username;
    my $dest = $self->get_tile_rel($ox,$oy);
    return unless $dest == $other->tile;
    print $self->symbol, '→', $other->symbol, "\n";
    my $damage = 5 + $self->muscle + int(rand($self->limbs));
    unless ($other->limbs <= 0) {
        my $diff = $other->limbs - $self->limbs;
        my $evade = scaled_logistic($diff,10);
        if (rand() < $evade) {
            $kernel->post($server_session, 'broadcast', ['announce', "$selfname missed."]);
            return;
        }
    }
    $other->cur_hp($other->cur_hp - $damage);
    delete $other->{actions};
    $kernel->post($server_session, 'broadcast', ['announce', "$selfname hit $othername for $damage damage."]);
    if ($other->alive) {
        $kernel->post($server_session, 'broadcast', ['change_object', $other->id, {'cur_hp'=>$other->cur_hp}]);
    }
    else {
        $kernel->post($server_session, 'broadcast', ['announce', "$selfname killed $othername."]);
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
   $kernel->alarm_remove_all();
   $place->objects->{$heap->{id}}->tile->leave($place->objects->{$heap->{id}});
   delete $place->objects->{$heap->{id}};
}

sub connection_broadcast {
   my ($kernel, $session, $heap, $message) = @_[KERNEL, SESSION, HEAP, ARG0];

   $heap->{wheel}->put($message);
}

1;
