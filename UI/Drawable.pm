package UI::Drawable;

use Moose::Role;

has 'panel' => (is=>'rw',isa=>'Curses::Panel',required=>1);
has 'symbol' => (is=>'rw',isa=>'Str',required=>1);
has 'color' => (is=>'rw');
has 'x' => (is=>'rw',isa=>'Int',required=>1);
has 'y' => (is=>'rw',isa=>'Int',required=>1);

sub draw {
    my $self = shift;

    $self->panel->panel_window->attron($self->color);
    $self->panel->panel_window->addstr($self->y,$self->x,$self->symbol);
    $self->panel->panel_window->attroff($self->color);
}

1;
