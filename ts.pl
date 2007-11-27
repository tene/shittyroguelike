#!/usr/bin/perl -I.

use strict;

require Term::Screen;
use Term::ANSIColor;

use Player;
use Place;
use UI;

# Do some setup
my $ui = UI->new();

my $place = Place->new();
$place->load($ARGV[0] || 'map1.txt');

# Create some initial player
my $player = Player->new(x => 5,
             y => 5,
             char => '∂',
             color => 'bold blue',
             place => $place,
         );

$ui->place($place);
$ui->player($player);


sub move_rel {
    my ($x,$y) = @_;
    $ui->clear_player();
    $player->move_to($player->x + $x,$player->y + $y);
    $ui->draw_player();
}

$ui->setup();

$ui->redraw();

my $c = $ui->scr->getch();
while ($c ne 'q') {
    if($c eq 'ku' || $c eq 'k') {
        move_rel(0,-1);
    }
    elsif($c eq 'kd' || $c eq 'j') {
        move_rel(0,1);
    }
    elsif($c eq 'kl' || $c eq 'h') {
        move_rel(-1,0);
    }
    elsif($c eq 'kr' || $c eq 'l') {
        move_rel(1,0);
    }
$c = $ui->scr->getch();      # doesn't need Enter key 
}

$ui->teardown();
