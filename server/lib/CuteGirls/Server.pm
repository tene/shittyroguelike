package CuteGirls::Server;

use FindBin::libs;
use FindBin;

use POE qw(Wheel::SocketFactory Wheel::ReadWrite
                    Driver::SysRW Filter::Reference);
use Data::Dumper;
use YAML::Syck;

use Player;
use Place;
use Object;

use Perl6::Slurp;
use Perl6::Subs;
use Switch 'Perl6';

chdir "$FindBin::Bin";

my $default_port = 3456;
my $server_session;
my $place;
my $players;
-f 'races.yaml' or die 'Race definition file (races.yaml) missing!';
my $races = LoadFile('races.yaml') or die 'Could not load race definition file (races.yaml)!';

-f 'gods.yaml' or die 'God definition file (gods.yaml) missing!';
my $gods = LoadFile('gods.yaml') or die 'Could not load god definition file (gods.yaml)!';

# help bound between two values
sub scaled_logistic ($value, $divisor) {
    return 1/(1+exp(- $value/$divisor));
}

sub new ($self, $map, $port, $reset) {
    $default_port ||= $port;

    if( $reset )
    {
	print "Clearing out player file.\n";
	unlink 'players.yaml';
    }

    $players = -f 'players.yaml' ? LoadFile('players.yaml') : {};

    $place = Place->new();
    $place->get($map);
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
    # create the listening server socket
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

=head1 C<server_broadcast>

Broadcast a message to all connected clients

=cut

sub server_broadcast {
   my ($kernel, $session, $heap, $message) = @_[KERNEL, SESSION, HEAP, ARG0];

   for my $conn (@{$heap->{connections}}) {
       $kernel->post($conn,'broadcast',$message);
   }
}

=head1 C<connection_start>

Accept a connection and set up a reader wheel that handles chunking, YAML, etc.

=cut

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

=head1 C<connection_input>

Accept input of the form [command, ...] and redispatch to the 'command' event with arguments of ...

=cut

sub connection_input {
    my ($kernel, $session, $heap, $input) = @_[KERNEL, SESSION, HEAP, ARG0];

    # DSB
    my ($command, @args) = @$input;

    # redispatch
    $kernel->post($session, $command, @args);
}

=head1 C<login>

Sent on a new connection.  If we don't already know this user, send them to 'create new user' form.

=cut

sub login {
    my ($kernel, $session, $heap, $username) = @_[KERNEL, SESSION, HEAP, ARG0];
    if (defined $players->{$username}) {
        $heap->{wheel}->put(['new_map', $place->to_ref]);
        $heap->{wheel}->put(['assign_id', $session->ID]);
    }
    else {
        send_create_form($heap->{wheel});
    }
}

=head1 C<send_create_form>

Helper function to send a 'new character' form to the client.

=cut

sub send_create_form {
    my $wheel = shift;
    # args are text to display on the form, list of gods, list of colors, list of races
    $wheel->put(['create_player',
	    'create new character',
	    $gods,
	    [qw(red green yellow blue magenta cyan white)],
	    $races]);
}

=head1 C<register>

Registration request from a client.

=cut

sub register {
    my ($kernel, $session, $heap, $username, $race, $god, $color) = @_[KERNEL, SESSION, HEAP, ARG0, ARG1, ARG2, ARG3];
    my $symbol = $races->{$race}->{symbol};
    if (defined $players->{$username}) { # this username is taken
	send_create_form($heap->{wheel});
    }
    else {
	$username ||= 'nobody';
	$symbol ||= substr $username,0,1;
	$color ||= 'red';
	$players->{$username} = {race=>$race,god=>$god,color=>$color};
	DumpFile('players.yaml', $players);
	$heap->{wheel}->put(['new_map', $place->to_ref]);
	$heap->{wheel}->put(['assign_id', $session->ID]);
    }
}

=head1 C<add_player>

Create a new Player object, insert it into the map, set up a regen tick, etc.

=cut

sub add_player {
    my ($kernel, $session, $heap, $id, $username) = @_[KERNEL, SESSION, HEAP, ARG0, ARG1];

    # grab stuff from the players hash
    my $fg = $players->{$username}->{color};
    my $god = $players->{$username}->{god};
    my $bg = 'black';

    # grab stuff from the race info table
    my $race = $races->{$players->{$username}->{race}};
    my $symbol = $race->{symbol};
    my $hp = ($race->{organs} + 13) * 10;

    $kernel->post($server_session, 'broadcast', ['announce', "$username, a loyal follower of $god, has arrived."]);
    my ($origin) = grep {(ref $_) eq 'Entrance'} values %{$place->objects};
    my ($x, $y) = ($origin->x, $origin->y);
    print "Adding a new player: $id $symbol $fg $bg $y $x\n";
    $heap->{id} = $id;

    # Create a new player object and save it in the objects table in the Place
    $place->insert(Player->new(
            id       => $id,
            username => $username,
            symbol   => $symbol,
            fg       => $fg,
            bg       => $bg,
            x        => $x,
            y        => $y,
            max_hp   => $hp,
            cur_hp   => $hp,
            place    => $place,
            map {$_ => 13 + $race->{$_} } qw/muscle organs limbs eyes scholarly practical physical social/,
        ));

    # set the map tile as filled.  dirty hack.
    tile_of($place->objects->{$id})->vasru(0);

    # tell all the connected clients about the new player
    $kernel->post($server_session, 'broadcast', ['add_player', $id, $place->objects->{$id}->to_hash, $y, $x]);

    # register a callback for the player's regen tick
    $kernel->delay_set('tick',rand() + scaled_logistic($race->{limbs},20));
}

=head1 C<object_move_rel>

Move an object relative to its current position

=cut

sub object_move_rel {
    my ($kernel, $session, $heap, $id, $ox, $oy) = @_[KERNEL, SESSION, HEAP, ARG0, ARG1, ARG2];
    my $player = $place->objects->{$id};
    my $source = tile_of($player);
    my $dest = tile_at($source->x + $ox,$source->y + $oy);

    # don't move it if the hackish "can't hold anything more" flag is set on the destination tile
    return unless $dest->vasru;

    # update the state of the map
    tile_of($player)->leave($player);
    $dest->enter($player);

    # broadcast the event to all clients
    $kernel->post($server_session, 'broadcast', ['object_move_rel', $id, $ox, $oy]);
}

=head1 C<player_move_rel>

Add a 'move' event to the player's "actions" queue.
Schedule a handler event if this is the only item in the action queue.

=cut

sub player_move_rel {
    my ($kernel, $session, $heap, $ox, $oy) = @_[KERNEL, SESSION, HEAP, ARG0, ARG1];
    my $self = $place->objects->{$session->ID};
    push @{$self->{actions}}, ['move',$ox,$oy];
    # If the item we just added is the only one, then there's no handler
    # event already scheduled
    unless (@{$self->{actions}} > 1) {
        $kernel->delay_set('act',scaled_logistic(13-$self->limbs,5)/4);
    }
}

=head1 C<tick>

Handle HP regen here.  We also will need to handle shit like poison, some special effects, some racial shit, anything that depends on the character's metabolism.

=cut

sub tick {
    my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];

    # grab the player for this client session
    my $self = $place->objects->{$session->ID};
    return unless $self; # bail out if the player is missing (has quit, f.e.)
    if ($self->cur_hp < $self->max_hp) {
        # some random bullshit algorithm
        my $next = int($self->cur_hp + $self->organs/4 + $self->physical/2 + rand(2));
        # set cur_hp to min of max_hp and previous cur_hp + bullshit
        $self->cur_hp(($next > $self->max_hp) ? $self->max_hp : $next );

        # send a change event to every client
        $kernel->post($server_session, 'broadcast', ['change_object', $self->id, {'cur_hp'=>$self->cur_hp}]);
    }

    # schedule another tick at now + bullshit
    $kernel->delay_set('tick',rand() + 20/$self->limbs);
}

=head1 C<act>

Process an item from the actions queue and schedule the next event.

=cut

sub act {
    my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
    my $self = $place->objects->{$session->ID};
    return unless $self;
    my ($act, @args) = @{shift @{$self->{actions}}};
    if ($act eq 'move') {
        $kernel->call($session, 'object_move_rel', $session->ID, @args);
    }
    if (@{$self->{actions}} > 0) { # there are still items in the queue
        # schedule another run at now+bullshit
        $kernel->delay_set('act',scaled_logistic(13-$self->limbs,5)/4);
    }
}

=head1 C<attack>

Try to kill a dude.

=cut

sub attack {
    my ($kernel, $session, $heap, $id, $ox, $oy) = @_[KERNEL, SESSION, HEAP, ARG0, ARG1, ARG2];
    # grab the appropriate character for the current client
    my $self = $place->objects->{$session->ID};
    my $selfname = $self->username;
    my $other = $place->objects->{$id};
    my $othername = $other->username;

    # find the tile in the direction specified
    my $source = tile_of($self);
    my $dest = tile_at($source->x + $ox,$source->x + $oy);

    # check to make sure the dude specified is in the tile.  bail out otherwise
    return unless grep {$_->id eq $id} @{$dest->contents};

    # debugging on the server console
    print $self->symbol, '→', $other->symbol, "\n";

    # We'll deal exactly bullshit damage.
    my $damage = 5 + $self->muscle + int(rand($self->limbs));

    # Check for evasion unless the other dude has a limbs stat 0 o rbelow
    unless ($other->limbs <= 0) {
        # difference between the limbs stats
        my $diff = $other->limbs - $self->limbs;
        my $evade = scaled_logistic($diff,10);
        if (rand() < $evade) {
            $kernel->post($server_session, 'broadcast', ['announce', "$selfname missed."]);
            return;
        }
    }
    $other->cur_hp($other->cur_hp - $damage);

    # cancel all pending actions for the dude we just hurt
    delete $other->{actions};

    # announce the attack to everyone
    $kernel->post($server_session, 'broadcast', ['announce', "$selfname hit $othername for $damage damage."]);
    if ($other->alive) {
        # broadcast the damage to all clients
        $kernel->post($server_session, 'broadcast', ['change_object', $other->id, {'cur_hp'=>$other->cur_hp}]);
    }
    else {
        # broadcast the death
        $kernel->post($server_session, 'broadcast', ['announce', "$selfname killed $othername."]);

        # death is SO hackish right now.  srsly.
        $kernel->post($server_session, 'broadcast', ['change_object', $other->id, $other->death()]);
    }
}

=head1 C<drop_item>

Create a bullshit item that will delete itself.
Eventually this should handle dropping an inventory item.

=cut

sub drop_item {
    my ($kernel, $session, $heap, $symbol,$fg,$bg) = @_[KERNEL, SESSION, HEAP, ARG0, ARG1, ARG2];

    # Everything here should be straightforward.  Ask if you need explained.
    my $player = $place->objects->{$heap->{id}};
    my $obj = Object->new(fg=>$fg,bg=>$bg,symbol=>$symbol,x=>$player->x,y=>$player->y);
    $place->objects->{$obj->id} = $obj;
    $kernel->post($server_session,'broadcast',['drop_item',$heap->{id},$obj->to_hash]);
    tile_of($player)->enter($obj);
    my $rand = 5+rand(rand(rand(100))); # shitty skewing towards the bottom
    $kernel->delay_set('change_object',$rand/2,$obj->id,{'symbol'=>'°','fg'=>'magenta'});
    $kernel->delay_set('remove_object',$rand,$obj->id);
}

=head1 C<remove_object>

Delete an object from the map.

=cut

sub remove_object {
    my ($kernel, $session, $heap, $id) = @_[KERNEL, SESSION, HEAP, ARG0];
    tile_of($place->objects->{$id})->leave($place->objects->{$id});
    delete $place->objects->{$id};

    # tell everyone about it
    $kernel->post($server_session, 'broadcast', ['remove_object', $id]);
}

=head1 C<change_object>

Modify an attribute of an object.
Accepts a hash and for each pair in the hash, calls a method named like the hash key with the value of the hash value.

=cut

sub change_object {
    my ($kernel, $session, $heap, $id, $changes) = @_[KERNEL, SESSION, HEAP, ARG0, ARG1];
    my $obj = $place->objects->{$id};

    # hackish, I think.  Maybe we need some sanity checking on the changes hash
    for my $attr (keys %{$changes}) {
        $obj->$attr($changes->{$attr});
    }
    $kernel->post($server_session, 'broadcast', ['change_object', $id, $changes]);
}

=head1 C<chat>

Casual conversation.

=cut

sub chat {
    my ($kernel, $session, $heap, $id, $message) = @_[KERNEL, SESSION, HEAP, ARG0, ARG1];
    # relay the chat message to EVERYONE.  We should be more selective.
    $kernel->post($server_session, 'broadcast', ['chat', $id, $message]);
}

=head1 C<connection_error>

Clean shit up if there's an error in the client connection.

=cut

sub connection_error {
   my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
   return unless defined($place->objects->{$heap->{id}});

   # tell all clients to remove the character object
   $kernel->post($server_session, 'broadcast', ['remove_object', $heap->{id}]);

   # remove all scheduled events
   $kernel->alarm_remove_all();

   # remove the character from the map
   tile_of($place->objects->{$heap->{id}})->leave($place->objects->{$heap->{id}});
   delete $place->objects->{$heap->{id}};
}

=head1 C<connection_broadcast>

Send a message to a connected client.  I don't know why we have this.  It's not used anywhere, and is a trivial wrapper.  Maybe for scheduling...

=cut

sub connection_broadcast {
   my ($kernel, $session, $heap, $message) = @_[KERNEL, SESSION, HEAP, ARG0];

   $heap->{wheel}->put($message);
}

sub tile_of {
    my $i = shift;
    $place->tile($i->x,$i->y);
}

sub tile_at {
    my ($x,$y) = @_;
    $place->tile($x,$y);
}

1;
