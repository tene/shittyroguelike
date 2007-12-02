package UI::Drawable;

use Moose::Role;

has 'panel' => (is=>'rw',isa=>'Curses::Panel',required=>1);
has 'symbol' => (is=>'rw',isa=>'Str',required=>1);
has 'color' => (is=>'rw',isa=>'Str',required=>1,default=>'white');
has 'x' => (is=>'rw',isa=>'Int',required=>1);
has 'y' => (is=>'rw',isa=>'Int',required=>1);

sub draw {
    my $self = shift;

    #print color $self->color;
    $self->panel->panel_window->addch($self->y,$self->x,$self->symbol);
}

1;
