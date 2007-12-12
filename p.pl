#!/usr/bin/perl

use FindBin::libs;

use Curses;
use POE qw(Wheel::Curses);
use Switch 'Perl6';

use Player;
use Place;
use Place::Thing;
use UI;

POE::Session->create
  ( inline_states =>
      { _start => \&_start,
        got_keystroke => \&keystroke_handler,
        player_move_rel => \&player_move_rel,
      }
  );

POE::Kernel->run();
exit;

sub _start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    binmode(STDOUT,':utf8');

    $heap->{console} = POE::Wheel::Curses->new(
        InputEvent => 'got_keystroke'
    );

    $heap->{ui} = UI->new();
    $heap->{place} = Place->new();
    $heap->{place}->load($ARGV[0] || 'maps/map1.txt',$heap->{ui}->place_panel,$heap->{ui});

    $heap->{ui}->place($heap->{place});

    $heap->{ui}->setup();

    $heap->{my_id} = 0;

    $heap->{place}->chart->[3][3]->enter(Place::Thing->new(color=>$heap->{ui}->colors->{'red'}->{'black'},symbol=>'%'));

    $heap->{ui}->redraw();
    ungetch('r');
    $heap->{players} = { };
    $kernel->yield('new_player',0,'@','blue','black',5,5);
}

sub keystroke_handler {
    my ($kernel, $heap, $keystroke, $wheel_id) = @_[KERNEL, HEAP, ARG0, ARG1];

     $heap->{ui}->output_panel->panel_window->addstr("keypress: $keystroke\n");
     $heap->{ui}->refresh();
     given ($keystroke) {
         when [KEY_UP, 'k'] { $kernel->yield('player_move_rel',$heap->{my_id},0,-1) }
         when [KEY_DOWN, 'j'] { $kernel->yield('player_move_rel',$heap->{my_id},0,1) }
         when [KEY_LEFT, 'h'] { $kernel->yield('player_move_rel',$heap->{my_id},-1,0) }
         when [KEY_RIGHT, 'l'] { $kernel->yield('player_move_rel',$heap->{my_id},1,0) }
         when 'r' { $heap->{ui}->redraw() }
         when 'd' { $heap->{players}->[$heap->{my_id}]->tile->add(Place::Thing->new(color=>$heap->{ui}->colors->{'green'}->{'black'},symbol=>'%')) }
         when 'q' {   } # how to tell POE to kill the session?
     }
}

sub player_move_rel {
    my ($kernel, $heap, $player_id, $x, $y) = @_[KERNEL, HEAP, ARG0, ARG1, ARG2];

    $heap->{players}->{$player_id}->move_rel($x,$y);
    $heap->{ui}->refresh();
}

sub new_player {
    my ($kernel, $heap, $id, $symbol, $fg, $bg, $y, $x) = @_[KERNEL, HEAP, ARG0, ARG1, ARG2, ARG3, ARG4, ARG5];
    my $player = Player->new(
                        symbol => $symbol,
                        color => $heap->{ui}->colors->{$fg}->{$bg},
                        tile => $heap->{place}->chart->[$y][$x],
                        );
    $heap->{players}->{$id} = $player;
    $heap->{ui}->output_panel->panel_window->addstr("New player '$symbol' at $x,$y\n");
    $heap->{ui}->refresh();
}
