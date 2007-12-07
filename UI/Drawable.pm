package UI::Drawable;

use Moose::Role;
use Perl6::Attributes;
use Perl6::Subs;

has 'panel' => (is=>'rw',isa=>'Curses::Panel',required=>1);
has 'symbol' => (is=>'rw',isa=>'Str',required=>1);
has 'color' => (is=>'rw');
has 'x' => (is=>'rw',isa=>'Int',required=>1);
has 'y' => (is=>'rw',isa=>'Int',required=>1);

method draw {
    ./panel->panel_window->attron($.color);
    ./panel->panel_window->addstr($.y,$.x,$.symbol);
    ./panel->panel_window->attroff($.color);
}

1;
