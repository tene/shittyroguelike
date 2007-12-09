#!/usr/bin/perl

use FindBin::libs;

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
my $player = Player->new(
             symbol => '@',
             color => $ui->colors->{'blue'}->{'black'},
             tile => $place->chart->[5][5],
         );

$ui->place($place);
$ui->player($player);


$ui->setup();

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
    elsif($c eq 'd') {
        $player->tile->add(Place::Thing->new(color=>$ui->colors->{'green'}->{'black'},symbol=>'%',tile=>$player->tile));
    }
    $ui->output_panel->panel_window->addstr("keypress: $c\n");
    $ui->refresh();
$c = $ui->win->getch();      # doesn't need Enter key 
}

$ui->teardown();
