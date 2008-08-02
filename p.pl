#!/usr/bin/perl

use strict;

use FindBin::libs;

use Curses;
use POE qw(Wheel::Curses Wheel::SocketFactory Wheel::ReadWrite Driver::SysRW Filter::Reference);
use Switch 'Perl6';

use Player;
use Place;
use Place::Thing;
use UI;
use PadWalker qw(peek_my);

my @sigils = ('a'..'z', 'A'..'Z', qw(
    @ & ! ~ ` ' " ? ^ _ , + ¿ ¡
));
my @colors = qw(black blue cyan green magenta red yellow white);

$_->meta->make_immutable(
    inline_constructor => 0,
    inline_accessors   => 1,
)
for qw(Player Place Place::Thing Place::Tile UI);

POE::Session->create
  ( inline_states =>
      { _start => \&_start,
        got_keystroke => \&keystroke_handler,
        help_keystroke => \&help_handler,
        chat_keystroke => \&chat_handler,
        object_move_rel => \&object_move_rel,
        add_player => \&add_player,
        chat => \&chat,
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
exit;

sub _start {
    my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];

    binmode(STDOUT,':utf8');

    $heap->{console} = POE::Wheel::Curses->new(
        InputEvent => 'got_keystroke'
    );

    $heap->{ui} = UI->new();

    my ($username,$symbol) = $heap->{ui}->get_login_info();
    $heap->{username} = $username;
    $heap->{symbol} = $symbol;

    $heap->{ui}->panels->{status}->show_panel();

    $heap->{ui}->debug("login info: $username $symbol");

    $heap->{ui}->refresh();

    $heap->{place} = Place->new();

    $heap->{ui}->place($heap->{place});

    $heap->{ui}->setup();


    output("Welcome to CuteGirls!\nPress '?' for help.\n");
    $kernel->yield('connect_start');
}

sub connect_start {
    my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];

    $heap->{server} = POE::Wheel::SocketFactory->new(
           RemoteAddress  => '127.0.0.1',
           RemotePort     => 3456,
           SuccessEvent   => 'connect_success',
           FailureEvent   => 'connect_failure'
         );

}

sub assign_id {
    my ($heap, $id) = @_[HEAP, ARG0];
    $heap->{my_id} = $id;
    random_player($heap);
    #output("assigned id: $id\n");
    $heap->{ui}->refresh();
}

sub keystroke_handler {
    my ($kernel, $heap, $keystroke, $wheel_id) = @_[KERNEL, HEAP, ARG0, ARG1];

    #output("keypress: $keystroke\n");
     $heap->{ui}->refresh();
     given ($keystroke) {
         when [KEY_UP, 'k'] { send_to_server('object_move_rel',$heap->{my_id},0,-1) }
         when [KEY_DOWN, 'j'] { send_to_server('object_move_rel',$heap->{my_id},0,1) }
         when [KEY_LEFT, 'h'] { send_to_server('object_move_rel',$heap->{my_id},-1,0) }
         when [KEY_RIGHT, 'l'] { send_to_server('object_move_rel',$heap->{my_id},1,0) }
         when 'n' { send_to_server('remove_object',$heap->{my_id}); random_player($heap); };
         when ["\r", "\n"] {
             $heap->{console}->[2] = 'chat_keystroke';
             my $player = $heap->{place}->objects->{$heap->{my_id}};
             output_colored($player->symbol,$player->fg,$player->bg,'input');
             $heap->{ui}->output(': ', 'input');
             $heap->{ui}->redraw();
             curs_set(1);
         }
         when 'd' {
             my $player = $heap->{place}->objects->{$heap->{my_id}};
             send_to_server('drop_item','*','red','black'); 
         }
         when 'r' { $heap->{ui}->redraw() }
         when 's' { $heap->{ui}->update_status() }
         when '?' { $heap->{ui}->panels->{help}->top_panel(); $heap->{ui}->redraw(); $heap->{console}->[2] = 'help_keystroke'; }
         when 'q' { send_to_server('remove_object',$heap->{my_id}); delete $heap->{console}; delete $heap->{server_socket}  } # how to tell POE to kill the session?
     }
}

sub help_handler {
    my ($kernel, $heap, $keystroke, $wheel_id) = @_[KERNEL, HEAP, ARG0, ARG1];

    #output("help keypress: $keystroke\n");
     $heap->{ui}->refresh();
     given ($keystroke) {
         default { $heap->{ui}->panels->{help}->bottom_panel(); $heap->{ui}->redraw(); $heap->{console}->[2] = 'got_keystroke'; }
     }
}

sub chat_handler {
    my ($kernel, $heap, $keystroke, $wheel_id) = @_[KERNEL, HEAP, ARG0, ARG1];

    #output("help keypress: $keystroke\n");
     $heap->{ui}->refresh();
     given ($keystroke) {
         when '' { # escape
             $heap->{console}->[2] = 'got_keystroke';
             $heap->{chat_message} = '';
             $heap->{ui}->output("\n",'input');
             $heap->{ui}->redraw();
             curs_set(0);
         }
         when [263, ''] { # handle backspace
             my $msg = substr($heap->{chat_message},0,-1);
             $heap->{chat_message} = $msg;
             $heap->{ui}->panels->{input}->panel_window->echochar("\n");
             my $player = $heap->{place}->objects->{$heap->{my_id}};
             output_colored($player->symbol,$player->fg,$player->bg,'input');
             $heap->{ui}->output(': ', 'input');
             $heap->{ui}->panels->{input}->panel_window->addstr($msg);
             $heap->{ui}->redraw() 
         }
         when ["\r", "\n"] { 
             send_to_server('chat',$heap->{my_id},$heap->{chat_message}) if ((length $heap->{chat_message}) > 0);
             $heap->{console}->[2] = 'got_keystroke';
             $heap->{chat_message} = '';
             $heap->{ui}->output("\n",'input');
             $heap->{ui}->redraw();
             curs_set(0);
         }
         default {
             $heap->{chat_message} .= $keystroke;
             $heap->{ui}->panels->{input}->panel_window->echochar($keystroke);
             $heap->{ui}->redraw();
         }
     }
}

sub random_player {
    my $heap = shift;
    my $symbol = $heap->{symbol} || $sigils[int(rand $#sigils)];
    my $username = $heap->{username} || 'Player' . $heap->{my_id};
    my $fg = $colors[1 + int(rand ($#colors - 1))];
    #my $bg = $colors[int(rand ($#colors - 1))];
    send_to_server('add_player',$heap->{my_id},$username,$symbol,$fg,'black',5,5) 
}

sub send_to_server {
    my $socket = ${peek_my(1)->{'$heap'}}->{server_socket};
    $socket->put(\@_);
}

sub object_move_rel {
    my ($kernel, $heap, $player_id, $x, $y) = @_[KERNEL, HEAP, ARG0, ARG1, ARG2];
    my $player = $heap->{place}->objects->{$player_id};
    my $before = $player->tile;
    $player->move_rel($x,$y);
    $heap->{ui}->drawtile($before);
    $heap->{ui}->drawtile($player->tile);
    #output("Player $player_id moving $x,$y\n");
    $heap->{ui}->refresh();
}

sub add_player {
    my ($kernel, $heap, $id, $username, $symbol, $fg, $bg, $y, $x) = @_[KERNEL, HEAP, ARG0, ARG1, ARG2, ARG3, ARG4, ARG5, ARG6];
    my $player = Player->new(
                        username => $username,
                        symbol => $symbol,
                        fg => $fg,
                        bg => $bg,
                        tile => $heap->{place}->chart->[$y][$x],
                        id => $id,
                        );
    $heap->{place}->objects->{$id} = $player;
    output("New player $username(");
    output_colored($symbol,$fg,$bg);
    output(") at $x,$y id $id\n");
    $heap->{ui}->drawtile($player->tile);
    $heap->{ui}->update_status;
    $heap->{ui}->refresh();
}

sub chat {
    my ($kernel, $heap, $id, $message) = @_[KERNEL, HEAP, ARG0, ARG1];
    my $from = $heap->{place}->objects->{$id};
    output("$from->{username}(");
    output_colored($from->symbol,$from->fg,$from->bg);
    output("): $message\n");
    $heap->{ui}->refresh();
}

sub new_map {
    my ($kernel, $heap, $place) = @_[KERNEL, HEAP, ARG0];

    output("Building world, please wait...\n");

    $heap->{place} = $place;
    $heap->{ui}->{place} = $place;
    $heap->{ui}->update_status;
    #$heap->{place}->chart->[3][3]->enter(Place::Thing->new(color=>$heap->{ui}->colors->{'red'}->{'black'},symbol=>'%'));
    $heap->{ui}->refresh();
    $heap->{ui}->redraw();
    ungetch('r');
}

sub drop_item {
    my ($kernel, $heap, $id, $obj) = @_[KERNEL, HEAP, ARG0, ARG1];
    my $player = $heap->{place}->objects->{$id};
    $player->tile->enter($obj);
    $heap->{place}->objects->{$obj->id} = $obj;
    $heap->{ui}->drawtile($player->tile);
    $heap->{ui}->update_status();
    $heap->{ui}->refresh();
}

sub remove_object {
    my ($kernel, $heap, $id) = @_[KERNEL, HEAP, ARG0];
    unless ( defined($heap->{place}->objects->{$id}) ) {
        output("Attempt to remove invalid object id $id\n");
        $heap->{ui}->refresh();
        return;
    }
    my $symbol = $heap->{place}->objects->{$id}->symbol();
    $heap->{place}->objects->{$id}->clear();
    $heap->{ui}->drawtile($heap->{place}->objects->{$id}->tile);
    delete $heap->{place}->objects->{$id};
    $heap->{ui}->update_status();
    $heap->{ui}->refresh();
}

sub change_object {
    my ($kernel, $heap, $id, $changes) = @_[KERNEL, HEAP, ARG0, ARG1];
    unless ( defined($heap->{place}->objects->{$id}) ) {
        output("Attempt to change invalid object id $id\n");
        $heap->{ui}->refresh();
        return;
    }
    my $obj = $heap->{place}->objects->{$id};
    for my $attr (keys %{$changes}) {
        $obj->$attr($changes->{$attr});
    }
    $heap->{ui}->drawtile($heap->{place}->objects->{$id}->tile);
    $heap->{ui}->update_status();
    $heap->{ui}->refresh();
}

sub connect_success {
    my ($kernel, $heap, $socket) = @_[KERNEL, HEAP, ARG0];

    $heap->{server_socket} = POE::Wheel::ReadWrite->new(
         'Handle'     => $socket,
         'Driver'     => POE::Driver::SysRW->new,
         'Filter'     => POE::Filter::Reference->new,
         'InputEvent' => 'server_input',
         'ErrorEvent' => 'server_error',
         'AutoFlush'  => 1,
    );

}

sub connect_failure {
    die "couldn't connect to server\n";
}

sub server_input {
    my ($kernel, $heap, $input) = @_[KERNEL, HEAP, ARG0];

    my ($cmd, @rest) = @$input;

    $kernel->yield($cmd, @rest);
}

sub server_error {
    die "problem with network stuff I guess\n";
}

sub output {
    my $message = shift;
    my $panel = shift;
    ${peek_my(1)->{'$heap'}}->{ui}->output($message,$panel);
}

sub output_colored {
    my $message = shift;
    my $fg = shift;
    my $bg = shift;
    my $panel = shift;
    ${peek_my(1)->{'$heap'}}->{ui}->output_colored($message,$fg,$bg,$panel);
}
