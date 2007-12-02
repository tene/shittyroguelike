package Player;

use Moose;

with 'UI::Drawable';

has 'x' => (is=>'rw',isa=>'Int',required=>1);
has 'y' => (is=>'rw',isa=>'Int',required=>1);
has 'place' => (is=>'rw',isa=>'Place');
has 'tile' => (is=>'rw',isa=>'Place::Tile');

sub move_to {
    my ($self,$x,$y) = @_;
    return unless $self->place->chart->[$y][$x]->vasru();
    $self->tile->leave($self) if $self->tile;
    $self->x($x);
    $self->y($y);
    $self->tile($self->place->chart->[$y][$x]);
    $self->tile->enter($self);
}

1;
