#!/usr/bin/perl

use strict;

use FindBin::libs;
use FindBin;

chdir "$FindBin::Bin";

use Getopt::Long;
use Curses;
use POE qw(Wheel::Curses Wheel::SocketFactory Wheel::ReadWrite Driver::SysRW Filter::Reference);
use Switch 'Perl6';

use Player;
use Place;
use Object;
use UI;
use PadWalker qw(peek_my);

print "chdir $FindBin::Bin\n";

# disallow altering the class in exchange for improved instantiation speed
$_->meta->make_immutable(
    inline_constructor => 0,
    inline_accessors   => 1,
)
for qw(Player Place Place::Tile UI);

my $place;
my $ui;
my $my_id;
my $server;
my %keybindings;

# set up the initial session
POE::Session->create
  ( inline_states =>
      { _start => \&_start,
        got_keystroke => \&keystroke_handler,
        help_keystroke => \&help_handler,
        chat_keystroke => \&chat_handler,
        object_move_rel => \&object_move_rel,
        create_player => \&create_player,
        add_player => \&add_player,
        chat => \&chat,
        announce => \&announce,
        new_map => \&new_map,
        drop_item => \&drop_item,
        remove_object => \&remove_object,
        change_object => \&change_object,
        connect_start => \&connect_start,
        connect_success => \&connect_success,
        connect_failure => \&connect_failure,
        server_input => \&server_input,
        server_error => \&server_error,
        assign_id => \&assign_id,
      }
  );

POE::Kernel->run();
# exit when the session closes
exit;

# =head1 C<_start>
# 
# Initial setup.
# 
# =cut

sub _start {
    my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];

    my ($username);
    GetOptions("user:s" => \$username,
               "server:s" => \$server,);

    # possibly a workaround, I think
    binmode(STDOUT,':utf8');

    # start curses and set it to dispatch keystrokes to the appropriate event
    $heap->{console} = POE::Wheel::Curses->new(
        InputEvent => 'got_keystroke'
    );

    # create a new UI object
    $ui = UI->new();

    unless ($username) {
        ($username) = $ui->get_login_info(); # ask for a username
    }
    $heap->{username} = $username;

    # Show the status panel.  Shouldn't UI do this?
    $ui->panels->{status}->show_panel();

    $ui->debug("login info: $username");
    $ui->refresh();

    # the rest of this function is probably outdated.
    # We probably shouldn't even have a Place object until we get the map
    # from the server.
    $place = Place->new();
    $ui->place($place);

    $ui->setup();

    # Load the key bindings
    do 'keys.conf';

    output("Welcome to CuteGirls!\nPress '?' for help.\n");

    # Go connect to the server
    $kernel->yield('connect_start');
}

sub connect_start {
    my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];

    # set up a client socket that sends events to the right places
    $heap->{server} = POE::Wheel::SocketFactory->new(
           RemoteAddress  => $server || '127.0.0.1',
           RemotePort     => 3456,
           SuccessEvent   => 'connect_success',
           FailureEvent   => 'connect_failure'
         );

}

# =head1 C<assign_id>
# 
# The server assigned us an ID.
# Save it for later use and then ask the server to create a character for us.
# 
# =cut

sub assign_id {
    my ($heap, $id) = @_[HEAP, ARG0];
    $my_id = $id;
    create_me($heap);
    $ui->refresh();
}

# =head1 Key Binding Functions
# 
# These functions are used to set up key bindings in the keys.conf
# file.
# 
# =head2 C<clear_keybindings>
# 
# Empty the key binding list.
# 
# =cut

# Clear out all keybindings; used in the keys.conf file
sub clear_keybindings {
    %keybindings=();
}

# =head2 C<keybind>
# 
# Args: mode, key, binding.
# 
# Bind the given key to the given action in the given mode.
# 
# =cut

# Bind a key; used in the keys.conf file
sub keybind {
    my ($mode, $key, $binding) = @_;

    ${$keybindings{$mode}}{$key} = $binding;
}

# =head1 C<keystroke handler>
# 
# Main input event handler.  Handles keystrokes for normal mode.
# Think vi modes.
# 
# =cut

sub keystroke_handler {
    my ($kernel, $heap, $keystroke, $wheel_id) = @_[KERNEL, HEAP, ARG0, ARG1];

    #################
    #
    # %actions
    #
    # This is a hash of anonymous subs that users can point to to perform
    # various actions.  Basically, the keys in this hash are the target of
    # keybinding configurations that users can easily maintain.
    #
    #################

    my %actions;
    $actions{'move_up'} = sub { move(0,-1); };
    $actions{'move_down'} = sub { move(0,1); };
    $actions{'move_left'} = sub { move(-1,0); };
    $actions{'move_right'} = sub { move(1,0); };

    # reset character.  use in case of bugs.
    $actions{'reset'} = sub { send_to_server('remove_object',$my_id); create_me($heap); };

    # chat mode
    $actions{'enter_chat'} = sub {
	# Change the curses input wheel to emit 'chat_keystroke' events
	# instead of 'got_keystroke' events.
	$heap->{console}->[2] = 'chat_keystroke';
	my $player = $place->objects->{$my_id};

	# we really need to make some functions for colored output
	output_colored($player->symbol,$player->fg,$player->bg,'input');
	$ui->output(': ', 'input');
	$ui->refresh();

	# show the cursor
	curs_set(1);
    };

    # create a silly little expiring item
    # Eventually this should be for dropping inventory items
    $actions{'drop'} = sub {
	my $player = $place->objects->{$my_id};
	send_to_server('drop_item','*','red','black'); 
    };

    # redraw the screen.  use in case of UI bugs.
    $actions{'redraw'} = sub { $ui->redraw() };

    # update the status window.  again, in case of bugs.
    $actions{'update_status'} = sub { $ui->update_status() };

    # show the help screen.
    $actions{'help'} = sub {
	$ui->panels->{help}->top_panel();
	$ui->refresh();
	# Change the curses input wheel to emit 'help_keystroke' events
	# instead of 'got_keystroke' events.
	$heap->{console}->[2] = 'help_keystroke';
    };

    # quit
    $actions{'quit'} = sub {
	# politely tell the server to remove our character
	send_to_server('remove_object',$my_id);

	# clean up curses
	delete $heap->{console};

	# close the network socket
	delete $heap->{server_socket}
    };

    ##########
    # END %actions
    ##########

    $ui->refresh();

    if (exists ${$keybindings{'normal'}}{$keystroke} ) {
	# print "exists: ".$keybindings{$keystroke}.", ".$actions{$keybindings{$keystroke}}.".\n";
	$actions{${$keybindings{'normal'}}{$keystroke}}();
    }
}

# =head1 C<move>
# 
# Helper function to move the player around.
# 
# =cut

sub move {
    my ($x,$y) = @_;

    # find myself
    my $self = $place->objects->{$my_id};
    my $source = tile_of($self);
    my $dest = tile_at($source->x + $x, $source->y + $y);

    # look for living things in the tile we're moving into
    my ($player) = grep {$_->meta->does_role('Actor::Alive')} @{$dest->contents};

    # If there's something alive there, kill it.  Otherwise, move.
    if ($player) {
        send_to_server('attack',$player->id,$x,$y);
    }
    else {
        send_to_server('player_move_rel',$x,$y);
    }
}

# =head1 C<help_handler>
# 
# Deal with keystrokes while we're in help mode.
# When there's any keystroke, hide the help panel
# and reset the curses input wheel.
# 
# =cut

sub help_handler {
    my ($kernel, $heap, $keystroke, $wheel_id) = @_[KERNEL, HEAP, ARG0, ARG1];

    $ui->refresh();
    given ($keystroke) {
        default {
            # hide the help window
            $ui->panels->{help}->bottom_panel();
            # redraw the screen
            $ui->refresh();
            # reset the keystroke handler
            $heap->{console}->[2] = 'got_keystroke';
        }
    }
}

# =head1 C<chat_handler>
# 
# Deal with keystrokes while in chat mode.
# Escape goes back to normal mode.
# Backspace mostly works.
# Enter sends.
# All other keystrokes add to the chat message.
# 
# Can we maybe use readline here?
# I don't know, but this is pretty hackish.
# 
# =cut

sub chat_handler {
    my ($kernel, $heap, $keystroke, $wheel_id) = @_[KERNEL, HEAP, ARG0, ARG1];

    $ui->refresh();

    #################
    #
    # %actions
    #
    # This is a hash of anonymous subs that users can point to to perform
    # various actions.  Basically, the keys in this hash are the target of
    # keybinding configurations that users can easily maintain.
    #
    #################

    my %actions;

    # bail out of chat
    $actions{'leave_chat'} = sub { 
	# reset the input even thandler
	$heap->{console}->[2] = 'got_keystroke';
	# clear any saved message so far
	$heap->{chat_message} = '';
	# clear the chat input line
	$ui->output("\n",'input');
	$ui->refresh();
	# hide the cursor
	curs_set(0);
    };

    # handle backspace
    $actions{'backspace'} = sub { 
	# chop off the last character
	chop $heap->{chat_message};
	# clear the line
	$ui->panels->{input}->panel_window->echochar("\n");
	# print a prompt on the input line
	my $player = $place->objects->{$my_id};
	output_colored($player->symbol,$player->fg,$player->bg,'input');
	$ui->output(': ', 'input');
	# print the message so far on the input line
	$ui->panels->{input}->panel_window->addstr($heap->{chat_message});
	$ui->refresh() 
    };

    # send the message on 'enter'
    $actions{'send'} = sub {
	# tell the server
	send_to_server('chat',$my_id,$heap->{chat_message}) if ((length $heap->{chat_message}) > 0);
	# reset the input handler
	$heap->{console}->[2] = 'got_keystroke';
	# clear the saved message
	$heap->{chat_message} = '';
	# clear the input line
	$ui->output("\n",'input');
	# redraw the screen and hide the cursor
	$ui->refresh();
	curs_set(0);
    };

    if (exists ${$keybindings{'chat'}}{$keystroke} ) {
	# print "exists: ".$keybindings{$keystroke}.", ".$actions{$keybindings{$keystroke}}.".\n";
	$actions{${$keybindings{'chat'}}{$keystroke}}();
    } else {
	# Default action for all other characters
	# save the character
	$heap->{chat_message} .= $keystroke;
	# show the character
	$ui->panels->{input}->panel_window->echochar($keystroke);
	$ui->refresh();
    }

}

# =head1 C<create_me>
# 
# Helper function to ask the server to create a character object for us.
# 
# =cut

sub create_me {
    my $heap = shift;
    my $username = $heap->{username};
    send_to_server('add_player',$my_id,$username);
}

# =head1 C<send_to_server>
# 
# Helper function to send shit to the server with prettier syntax.
# 
# =cut

sub send_to_server {
    # Dig around in the caller lexpads for a variable named $heap
    my $heap = ${peek_my(1)->{'$heap'} || peek_my(2)->{'$heap'}};
    # grab the socket out of it
    my $socket = $heap->{server_socket};
    # redispatch with the same arguments we were called with
    $socket->put(\@_);
}

# =head1 C<object_move_rel>
# 
# The server told us to move something around.
# 
# =cut

sub object_move_rel {
    my ($kernel, $heap, $object_id, $x, $y) = @_[KERNEL, HEAP, ARG0, ARG1, ARG2];
    # find the object and the tile it's currently in
    my $object = $place->objects->{$object_id};
    my $before = tile_of($object) || return;
    # move the object
    my $dest = tile_at($before->x + $x, $before->y + $y);
    $before->leave($object);
    $dest->enter($object);

    # if we just moved ourself, refocus the UI
    if ($object_id == $my_id) {
        $ui->focus_x($object->x);
        $ui->focus_y($object->y);
        $ui->redraw();
    }
    else {
        # redraw the two affected tiles
        $ui->drawtile($before);
        $ui->drawtile(tile_of($object));
        $ui->refresh();
    }
}

# =head1 C<create_player>
# 
# The server is asking us to create a new character.
# The server gives us a lis tof acceptable gods, colors, and races.
# Give the user a little form and then send a registration request to the server.
# 
# This should be rewritten into several generic "choose from this list"
# questions from the server.
# 
# =cut

sub create_player {
    my ($kernel, $heap, $message, $gods, $colors, $races) = @_[KERNEL, HEAP, ARG0, ARG1, ARG2, ARG3];

    # give the user a little form to fill out.  It returns values
    # now, not indexes.
    my $race = $ui->choose_with_descs($races, "white", "black",
	    "Races", "yellow", "Race Description", "yellow" );
    my $god = $ui->choose_with_descs($gods, "white", "black",
	    "Gods", "yellow", "Gods Description", "yellow" );
    my $color = $ui->choose($colors, "white", "black",
	    "Colors", "yellow", "Colors Description", "yellow" );

    my $username = $heap->{username};
    # send a registration request to the server
    send_to_server('register',$username,$race,$god,$color);
}

# =head1 C<add_player>
# 
# The server is telling us about a new character in the world.
# It sends us an id, a hash of properties, and a position.
# 
# =cut

sub add_player {
    my ($kernel, $heap, $id, $p, $y, $x) = @_[KERNEL, HEAP, ARG0, ARG1, ARG2, ARG3];
    # create a Player object
    my $player = Player->new(
        %$p,
        id => $id,
        place => $place,
	y => $y,
	x => $x,
    );
    # store it in the global objects hash
    $place->insert($player);

    # print some debug shit.
    # We need a helper function for this.
    output('New player '.$player->username.'(');
    output_colored($player->symbol,$player->fg,$player->bg);
    output(") at $x,$y id $id\n");

    # if it's us, refocus the UI
    if ($id == $my_id) {
        $ui->focus_x($x);
        $ui->focus_y($y);
        $ui->redraw();
    }
    else {
        $ui->drawtile(tile_of($player));
    }
    $ui->update_status;
    $ui->refresh();
}

# =head1 C<chat>
# 
# The server is telling us about someone chatting.
# Display it to the log area.
# 
# =cut

sub chat {
    my ($kernel, $heap, $id, $message) = @_[KERNEL, HEAP, ARG0, ARG1];
    my $from = $place->objects->{$id};
    # display shit
    # We need a helper function
    output("$from->{username}(");
    output_colored($from->symbol,$from->fg,$from->bg);
    output("): $message\n");
    $ui->refresh();
}

# =head1 C<announce>
# 
# Generic announcement from the server.
# Display it in the log area.
# 
# =cut

sub announce {
    my ($kernel, $heap, $message) = @_[KERNEL, HEAP, ARG0, ARG1];
    output("announcement: $message\n");
    $ui->refresh();
}

# =head1 C<new_map>
# 
# The server sent us a map.  We really need to do more here before
# we can support moving between areas.
# 
# Right now the server sends us a list of lists of tiles represented by hashes.
# 
# =cut

sub new_map {
    my ($kernel, $heap, $placeref) = @_[KERNEL, HEAP, ARG0];

    output("Building world, please wait...\n");

    $place = Place->new();
    $place->load_from_ref($placeref);
    $ui->{place} = $place;
    $ui->update_status;
    $ui->refresh();
    $ui->redraw();

    # queue a refresh event for the keystroke handler
    # probably a bug workaround
    ungetch('r');
}

# =head1 C<drop_item>
# 
# Create an object at the location of another object.
# 
# =cut

sub drop_item {
    my ($kernel, $heap, $id, $obj) = @_[KERNEL, HEAP, ARG0, ARG1];
    # Won't necessarily be a player, but that's all we use it for
    my $player = $place->objects->{$id};

    # create a new Object using the attributes given to us
    $obj = Object->new(%$obj);

    # add it to the map at the right place
    tile_of($player)->enter($obj);
    $place->objects->{$obj->id} = $obj;
    $ui->drawtile(tile_of($player));
    $ui->update_status();
    $ui->refresh();
}

# =head1 C<remove_object>
# 
# Remove an object from the map
# 
# =cut

sub remove_object {
    my ($kernel, $heap, $id) = @_[KERNEL, HEAP, ARG0];
    unless ( defined($place->objects->{$id}) ) {
        output("Attempt to remove invalid object id $id\n");
        $ui->refresh();
        return;
    }
    my $obj = $place->objects->{$id};
    my $symbol = $obj->symbol();
    tile_of($obj)->leave($obj);
    $ui->drawtile(tile_of($obj));
    delete $place->objects->{$id};
    $ui->update_status();
    $ui->refresh();
}

# =head1 C<change_object>
# 
# Modify an object in some way.
# The server gives us a hash of {attribute=>value} to set.
# 
# =cut

sub change_object {
    my ($kernel, $heap, $id, $changes) = @_[KERNEL, HEAP, ARG0, ARG1];
    unless ( defined($place->objects->{$id}) ) {
        output("Attempt to change invalid object id $id\n");
        $ui->refresh();
        return;
    }
    my $tile = tile_of($place->objects->{$id});
    my $obj = $place->objects->{$id};

    # kinda hackish.  Just call the method with the name of the attribute.
    for my $attr (keys %{$changes}) {
        $obj->$attr($changes->{$attr});
    }

    # redraw shit
    $ui->drawtile(tile_of($place->objects->{$id}));
    $ui->drawtile($tile);
    $ui->update_status();
    $ui->refresh();
}

# =head1 C<connect_success>
# 
# Event for when we successfully connect to the server.
# Set up a filter wheel to handle chunking, yaml decoding, etc.
# 
# Sends a login request to the server once we've set up the socket properly.
# 
# =cut

sub connect_success {
    my ($kernel, $heap, $socket) = @_[KERNEL, HEAP, ARG0];

    $heap->{server_socket} = POE::Wheel::ReadWrite->new(
         'Handle'     => $socket,
         'Driver'     => POE::Driver::SysRW->new,
         'Filter'     => POE::Filter::Reference->new('YAML'),
         'InputEvent' => 'server_input',
         'ErrorEvent' => 'server_error',
         'AutoFlush'  => 1,
    );
    send_to_server('login',$heap->{username});
}

# =head1 C<connect_failure>
# 
# Couldn't connect, so we bail out.
# 
# =cut

sub connect_failure {
    die "couldn't connect to server\n";
}

# =head1 C<server_input>
# 
# The server said something.
# 
# Right now we have a POE state for every command the server would send,
# so just redispatch to that state with the command arguments we were
# given as arguments to the state.
# 
# =cut

sub server_input {
    my ($kernel, $heap, $input) = @_[KERNEL, HEAP, ARG0];

    my ($cmd, @rest) = @$input;

    $kernel->yield($cmd, @rest);
}

# =head1 C<server_error>
# 
# All errors with the connection go here.
# We don't even try to do something reasonable.
# Just die.
# 
# =cut

sub server_error {
    die "problem with network stuff I guess\n";
}

# =head1 C<output>
# 
# Helper method to redispatch output calls to the global $ui object.
# 
# =cut

sub output {
    my $message = shift;
    my $panel = shift;
    $ui->output($message,$panel);
    $ui->refresh();
}

# =head1 C<output_colored>
# 
# Helper function to redispatch output_colored calls to the global $ui object.
# 
# =cut

sub output_colored {
    my $message = shift;
    my $fg = shift;
    my $bg = shift;
    my $panel = shift;
    $ui->output_colored($message,$fg,$bg,$panel);
    $ui->refresh();
}

sub tile_of {
    my $i = shift;
    $place->tile($i->x,$i->y);
}

sub tile_at {
    my ($x,$y) = @_;
    $place->tile($x,$y);
}
