#!/usr/bin/perl

use FindBin::libs;

use Curses;
use POE qw(Wheel::Curses);

use Player;
use Place;
use Place::Thing;
use UI;

POE::Session->create
  ( inline_states =>
      { _start => \&_start,
        got_keystroke => \&keystroke_handler,
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

    $heap->{player} = Player->new(
                                symbol => '@',
                                color => $heap->{ui}->colors->{'blue'}->{'black'},
                                place => $heap->{place},
                                );
    $heap->{ui}->place($heap->{place});
    $heap->{ui}->player($heap->{player});

    $heap->{ui}->setup();

    $heap->{player}->move_to(5,5);

    ungetch('r');
}

sub keystroke_handler {
    my ($kernel, $heap, $keystroke, $wheel_id) = @_[KERNEL, HEAP, ARG0, ARG1];

     if($keystroke == KEY_UP || $keystroke eq 'k') {
         $heap->{player}->move_rel(0,-1);
     }
     elsif($keystroke eq KEY_DOWN || $keystroke eq 'j') {
         $heap->{player}->move_rel(0,1);
     }
     elsif($keystroke eq KEY_LEFT || $keystroke eq 'h') {
         $heap->{player}->move_rel(-1,0);
     }
     elsif($keystroke eq KEY_RIGHT || $keystroke eq 'l') {
         $heap->{player}->move_rel(1,0);
     }
     elsif($keystroke eq 'r') {
         $heap->{ui}->redraw();
     }
     elsif($keystroke eq 'l') {
         $heap->{player}->tile->add(Place::Thing->new(color=>$heap->{ui}->colors->{'green'}->{'black'},symbol=>'%'));
     }
     elsif($keystroke eq 'q') {
         # how do I tell POE to quit?
     }
     $heap->{ui}->output_panel->panel_window->addstr("keypress: $keystroke\n");
     $heap->{ui}->refresh();
}
