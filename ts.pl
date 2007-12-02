#!/usr/bin/perl -I.

use strict;

no warnings;

use Player;
use Place;
use Place::Thing;
use UI;

binmode(STDOUT, ":utf8");

# Do some setup
my $ui = UI->new();

my $place = Place->new();
$place->load($ARGV[0] || 'maps/map1.txt',$ui->place_panel);

# Create some initial player
my $player = Player->new(x => 5,
             y => 5,
             symbol => '@',
             #char => '∂',
             color => 'bold blue',
             place => $place,
         );

$ui->place($place);
$ui->player($player);


$ui->setup();

$ui->redraw();
$player->move_to($player->x,$player->y);

my $c = $ui->win->getch();
while ($c ne 'q') {
    if($c eq 'ku' || $c eq 'k') {
        $player->move_rel(0,-1);
    }
    elsif($c eq 'kd' || $c eq 'j') {
        $player->move_rel(0,1);
    }
    elsif($c eq 'kl' || $c eq 'h') {
        $player->move_rel(-1,0);
    }
    elsif($c eq 'kr' || $c eq 'l') {
        $player->move_rel(1,0);
    }
    elsif($c eq 'r') {
        $ui->redraw();
    }
    elsif($c eq 'l') {
        $player->tile->add(Place::Thing->new(color=>'green',symbol=>'%'));
    }
    $ui->refresh();
$c = $ui->win->getch();      # doesn't need Enter key 
}

$ui->teardown();
