#!/usr/bin/perl

use strict;

use FindBin::libs;

use Getopt::Long;
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

my $place;
my $ui;
my $my_id;
my $server;

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
exit;

sub _start {
    my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];

    my ($username);
    GetOptions("user:s" => \$username,
               "server:s" => \$server,);

    binmode(STDOUT,':utf8');

    $heap->{console} = POE::Wheel::Curses->new(
        InputEvent => 'got_keystroke'
    );

    $ui = UI->new();

    if ($username) {
    }
    else {
        ($username) = $ui->get_login_info();
    }
    $heap->{username} = $username;

    $ui->panels->{status}->show_panel();

    $ui->debug("login info: $username");
    $ui->refresh();

    $place = Place->new();
    $ui->place($place);

    $ui->setup();


    output("Welcome to CuteGirls!\nPress '?' for help.\n");
    $kernel->yield('connect_start');
}

sub connect_start {
    my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];

    $heap->{server} = POE::Wheel::SocketFactory->new(
           RemoteAddress  => $server || '127.0.0.1',
           RemotePort     => 3456,
           SuccessEvent   => 'connect_success',
           FailureEvent   => 'connect_failure'
         );

}

sub assign_id {
    my ($heap, $id) = @_[HEAP, ARG0];
    $my_id = $id;
    random_player($heap);
    $ui->refresh();
}

sub keystroke_handler {
    my ($kernel, $heap, $keystroke, $wheel_id) = @_[KERNEL, HEAP, ARG0, ARG1];

    $ui->refresh();
    given ($keystroke) {
        when [KEY_UP, 'k'] { move(0,-1) }
        when [KEY_DOWN, 'j'] { move(0,1) }
        when [KEY_LEFT, 'h'] { move(-1,0) }
        when [KEY_RIGHT, 'l'] { move(1,0) }
        when 'n' { send_to_server('remove_object',$my_id); random_player($heap); };
        when ["\r", "\n"] {
            $heap->{console}->[2] = 'chat_keystroke';
            my $player = $place->objects->{$my_id};
            output_colored($player->symbol,$player->fg,$player->bg,'input');
            $ui->output(': ', 'input');
            $ui->refresh();
            curs_set(1);
        }
        when 'd' {
            my $player = $place->objects->{$my_id};
            send_to_server('drop_item','*','red','black'); 
        }
        when 'r' { $ui->redraw() }
        when 's' { $ui->update_status() }
        when '?' { $ui->panels->{help}->top_panel(); $ui->refresh(); $heap->{console}->[2] = 'help_keystroke'; }
        when 'q' { send_to_server('remove_object',$my_id); delete $heap->{console}; delete $heap->{server_socket}  } # how to tell POE to kill the session?
    }
}

sub move {
    my ($x,$y) = @_;
    my $self = $place->objects->{$my_id};
    my $dest = $self->get_tile_rel($x,$y);
    my ($player) = grep {$_->meta->does_role('Actor::Alive')} @{$dest->contents};
    if ($player) {
        send_to_server('attack',$player->id,$x,$y);
    }
    else {
        send_to_server('player_move_rel',$x,$y);
    }
}

sub help_handler {
    my ($kernel, $heap, $keystroke, $wheel_id) = @_[KERNEL, HEAP, ARG0, ARG1];

    $ui->refresh();
    given ($keystroke) {
        default { $ui->panels->{help}->bottom_panel(); $ui->refresh(); $heap->{console}->[2] = 'got_keystroke'; }
    }
}

sub chat_handler {
    my ($kernel, $heap, $keystroke, $wheel_id) = @_[KERNEL, HEAP, ARG0, ARG1];

    $ui->refresh();
    given ($keystroke) {
        when '' { # escape
            $heap->{console}->[2] = 'got_keystroke';
            $heap->{chat_message} = '';
            $ui->output("\n",'input');
            $ui->refresh();
            curs_set(0);
        }
        when [263, ''] { # handle backspace
            my $msg = substr($heap->{chat_message},0,-1);
            $heap->{chat_message} = $msg;
            $ui->panels->{input}->panel_window->echochar("\n");
            my $player = $place->objects->{$my_id};
            output_colored($player->symbol,$player->fg,$player->bg,'input');
            $ui->output(': ', 'input');
            $ui->panels->{input}->panel_window->addstr($msg);
            $ui->refresh() 
        }
        when ["\r", "\n"] { 
            send_to_server('chat',$my_id,$heap->{chat_message}) if ((length $heap->{chat_message}) > 0);
            $heap->{console}->[2] = 'got_keystroke';
            $heap->{chat_message} = '';
            $ui->output("\n",'input');
            $ui->refresh();
            curs_set(0);
        }
        default {
            $heap->{chat_message} .= $keystroke;
            $ui->panels->{input}->panel_window->echochar($keystroke);
            $ui->refresh();
        }
    }
}

sub random_player {
    my $heap = shift;
    my $username = $heap->{username} || 'Player' . $my_id;
    my $fg = $colors[1 + int(rand ($#colors - 1))];
    #my $bg = $colors[int(rand ($#colors - 1))];
    send_to_server('add_player',$my_id,$username,$fg,'black',50);
}

sub send_to_server {
    my $heap = ${peek_my(1)->{'$heap'} || peek_my(2)->{'$heap'}};
    my $socket = $heap->{server_socket};
    $socket->put(\@_);
}

sub object_move_rel {
    my ($kernel, $heap, $player_id, $x, $y) = @_[KERNEL, HEAP, ARG0, ARG1, ARG2];
    my $player = $place->objects->{$player_id};
    my $before = $player->tile;
    $player->move_rel($x,$y);
    $ui->drawtile($before);
    $ui->drawtile($player->tile);
    $ui->refresh();
}

sub create_player {
    my ($kernel, $heap, $message, $gods) = @_[KERNEL, HEAP, ARG0, ARG1];
    my ($symbol,$god) = $ui->get_new_player_info($message,$gods);
    my $username = $heap->{username};
    send_to_server('register',$username,$symbol,$god);
}

sub add_player {
    my ($kernel, $heap, $id, $username, $symbol, $fg, $bg, $hp, $y, $x) = @_[KERNEL, HEAP, ARG0, ARG1, ARG2, ARG3, ARG4, ARG5, ARG6, ARG7];
    my $player = Player->new(
                        username => $username,
                        symbol => $symbol,
                        fg => $fg,
                        bg => $bg,
                        tile => $place->chart->[$y][$x],
                        id => $id,
                        max_hp => $hp,
                        cur_hp => $hp,
                        place => $place,
                        );
    $place->objects->{$id} = $player;
    output("New player $username(");
    output_colored($symbol,$fg,$bg);
    output(") at $x,$y id $id\n");
    $ui->drawtile($player->tile);
    $ui->update_status;
    $ui->refresh();
}

sub chat {
    my ($kernel, $heap, $id, $message) = @_[KERNEL, HEAP, ARG0, ARG1];
    my $from = $place->objects->{$id};
    output("$from->{username}(");
    output_colored($from->symbol,$from->fg,$from->bg);
    output("): $message\n");
    $ui->refresh();
}

sub announce {
    my ($kernel, $heap, $message) = @_[KERNEL, HEAP, ARG0, ARG1];
    output("announcement: $message\n");
    $ui->refresh();
}

sub new_map {
    my ($kernel, $heap, $newplace) = @_[KERNEL, HEAP, ARG0];

    output("Building world, please wait...\n");

    $place = $newplace;
    $ui->{place} = $newplace;
    $ui->update_status;
    $ui->refresh();
    $ui->redraw();
    ungetch('r');
}

sub drop_item {
    my ($kernel, $heap, $id, $obj) = @_[KERNEL, HEAP, ARG0, ARG1];
    my $player = $place->objects->{$id};
    $player->tile->enter($obj);
    $place->objects->{$obj->id} = $obj;
    $ui->drawtile($player->tile);
    $ui->update_status();
    $ui->refresh();
}

sub remove_object {
    my ($kernel, $heap, $id) = @_[KERNEL, HEAP, ARG0];
    unless ( defined($place->objects->{$id}) ) {
        output("Attempt to remove invalid object id $id\n");
        $ui->refresh();
        return;
    }
    my $symbol = $place->objects->{$id}->symbol();
    $place->objects->{$id}->clear();
    $ui->drawtile($place->objects->{$id}->tile);
    delete $place->objects->{$id};
    $ui->update_status();
    $ui->refresh();
}

sub change_object {
    my ($kernel, $heap, $id, $changes) = @_[KERNEL, HEAP, ARG0, ARG1];
    unless ( defined($place->objects->{$id}) ) {
        output("Attempt to change invalid object id $id\n");
        $ui->refresh();
        return;
    }
    my $tile = $place->objects->{$id}->tile;
    my $obj = $place->objects->{$id};
    for my $attr (keys %{$changes}) {
        $obj->$attr($changes->{$attr});
    }
    $ui->drawtile($place->objects->{$id}->tile);
    $ui->drawtile($tile);
    $ui->update_status();
    $ui->refresh();
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
    send_to_server('login',$heap->{username});
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
    $ui->output($message,$panel);
    $ui->refresh();
}

sub output_colored {
    my $message = shift;
    my $fg = shift;
    my $bg = shift;
    my $panel = shift;
    $ui->output_colored($message,$fg,$bg,$panel);
    $ui->refresh();
}
