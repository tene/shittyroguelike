#!/usr/bin/perl
use v5.10.0;
use strict;
$ENV{'TERM'}='xterm-256color';
use Curses;

my $map = ();
while (my $line = <DATA>) {
    chomp $line;
    push @$map, [split //, $line];
}
my @shades = (16,232..255,231);
my @colors = (15,21,196);
my $shades = @shades - 1;
my %pl = (x => 40, y => 9 );
my $win = Curses->new;
start_color;
noecho;
curs_set 0;

my $colors = COLORS;
my $count = 1;
my %cache;
sub cp {
    my ($fg,$bg) = @_,0;
    return $cache{"$fg.$bg"} ||= $count++;
}
for my $bg (@shades) {
    for my $fg (232,15,21) { # 196 = red
        init_pair(cp($fg,$bg), $fg, $bg);
    }
}
sub dist {
    my ($x, $y) = @_;
    my $dx = $x-$pl{x};
    my $dy = $y-$pl{y};
    return sqrt( $dx**2 + $dy**2 );
}
sub light {
    my ($x, $y) = @_;
    my $d = 1 + dist($x,$y)/2;
    my $tile = $map->[$y]->[$x];
    my $i = $shades/$d;
    if ($tile eq ' ' || $tile eq '#') {
        $i = 0;
    }
    $shades[int($i)];
}
sub redraw {
    for my $x (0..$COLS) {
        for my $y (0..$LINES) {
            my $tile = $map->[$y]->[$x];
            my $bg = light($x,$y);
            my $fg = 15;
            attron(COLOR_PAIR(cp($fg,$bg)));
            addstr($y,$x,$tile);
            attroff(COLOR_PAIR(cp($fg,$bg)));
        }
    }
}
sub between {
    my ($n, $start, $end) = @_;
    return ($n+0.001 >= $start && $n-0.001 <= $end);
}
sub in_ranges {
    my ($ranges, $cell, $da) = @_;
    my $sa = $cell*$da;
    my $ca = ($cell+0.5)*$da;
    my $fa = ($cell+1)*$da;
    for my $r (@$ranges) {
        return 1 if between($sa, @$r) && between($ca, @$r) && between($fa, @$r);
        #return 1 if between($sa, @$r) && between($ca, @$r);
        #return 1 if between($ca, @$r) && between($fa, @$r);
    }
    return 0;
}
sub do_shadows {
    my ($ox, $oy) = @pl{'x','y'};
    clear;
    attron(COLOR_PAIR(cp(21,231)));
    addstr($oy, $ox, '@');
    attroff(COLOR_PAIR(cp(21,231)));
    for my $swap (0,1) {
        for my $axisdir (1,-1) {
            for my $rowdir (1,-1) {
                my $maxdepth = [$ox,$oy]->[$swap];
                $maxdepth = [$COLS,$LINES]->[$swap] - $maxdepth if $axisdir == 1;
                my $ranges = ();
                for my $depth (1..$maxdepth) {
                    my $start=0;
                    my $blocked = 0;
                    my $da = 1/($depth+1);
                    for my $cell (0..$depth) {
                        my $x = $ox + ($swap ? $cell*$rowdir : $depth*$axisdir);
                        my $y = $oy + ($swap ? $depth*$axisdir : $cell*$rowdir);
                        my $bg = light($x,$y);
                        my $fg = 15;
                        my $tile = $map->[$y]->[$x];
                        if (in_ranges($ranges, $cell, $da) || ($cell**2 + $depth**2 > 100)) {
                            $bg = $shades[0];
                            $fg = $shades[1];
                            attron(COLOR_PAIR(cp($fg,$bg)));
                            addstr($y, $x, $tile);
                            attroff(COLOR_PAIR(cp($fg,$bg)));
                            next;
                        }
                        if ($blocked == 0 && $tile eq '#') {
                            $blocked = 1;
                            $start = $cell*$da;
                        }
                        if ($blocked == 1 && $tile ne '#') {
                            $blocked = 0;
                            push @$ranges, [$start, $cell*$da];
                        }
                        attron(COLOR_PAIR(cp($fg,$bg)));
                        addstr($y, $x, $tile);
                        attroff(COLOR_PAIR(cp($fg,$bg)));
                    }
                    if ($blocked == 1) {
                        push @$ranges, [$start, 2];
                    }
                }
            }
        }
    }
}
my %act = (
    'q' => sub { return 0 },
    h => sub { $pl{x}-- },
    j => sub { $pl{y}++ },
    k => sub { $pl{y}-- },
    l => sub { $pl{x}++ },
    'DEFAULT' => sub { return 1 },
);
while (1) {
    #redraw();
    do_shadows();
    doupdate();
    refresh;
    my $ch = getch;
    my $action = $act{$ch} || $act{DEFAULT};
    last unless $action->();
}
endwin;

__DATA__
                   ########                                                     
                   #......##########                                            
                   #...............#                                            
  #############    #...............#######                #################     
 ##...........##   #......#######........#                #...............#     
##...######....##  #......#     #........#                #...............#     
#...##    #.....## ########     #######..#                #...............#     
#...# #####......##                   #..##################...............#     
#...###...........#####################...................................#     
#.........................................................................#     
#.......####.................................#################............#     
#....####  #.....##########################..#               #............#     
##...#     #....##                        #..#########       ##############     
 ###.###   #...##                      ####..........#                          
   #...#   #####                       #.............#                          
   ###.#                               #.............#                          
     #.#     ######################### #.............#                          
 #####.#     #.......................###.............#                          
 #.....##### #.......................................#                          
 #.#####...# #..#.......#........#...................#                          
 #.#####...###......#................###.............#                          
 #....................#.......#......# ###############                          
 #.........###.....#......#..........#                                          
 #.........# #.......................#                                          
 ########### #########################                                          
                                                                                
