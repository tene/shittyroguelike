#!/usr/bin/perl -I.

use strict;

no warnings;

use Curses;

use Player;
use Place;
use Place::Thing;
use UI;

$_->meta->make_immutable(
    inline_constructor => 0,
    inline_accessors   => 1,
)
for qw(Player Place Place::Thing UI);

binmode(STDOUT, ":utf8");

# Do some setup
my $ui = UI->new();

my $place = Place->new();
$place->load($ARGV[0] || 'maps/map1.txt',$ui->place_panel,$ui);

# Create some initial player
my $player = Player->new(x => 5,
             y => 5,
             symbol => '@',
             color => $ui->colors->{'blue'}->{'black'},
             place => $place,
         );

$ui->place($place);
$ui->player($player);


$ui->setup();

$player->move_to($player->x,$player->y);

ungetch('r');
$ui->redraw();
my $c = $ui->win->getch();
while ($c ne 'q') {
    if($c == KEY_UP || $c eq 'k') {
        $player->move_rel(0,-1);
    }
    elsif($c eq KEY_DOWN || $c eq 'j') {
        $player->move_rel(0,1);
    }
    elsif($c eq KEY_LEFT || $c eq 'h') {
        $player->move_rel(-1,0);
    }
    elsif($c eq KEY_RIGHT || $c eq 'l') {
        $player->move_rel(1,0);
    }
    elsif($c eq 'r') {
        $ui->redraw();
    }
    elsif($c eq 'l') {
        $player->tile->add(Place::Thing->new(color=>$ui->colors->{'green'}->{'black'},symbol=>'%'));
    }
    $ui->output_panel->panel_window->addstr("keypress: $c\n");
    $ui->refresh();
$c = $ui->win->getch();      # doesn't need Enter key 
}

$ui->teardown();
