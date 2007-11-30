package Player;

use Moose;

has 'x' => (is=>'rw',isa=>'Int',required=>1);
has 'y' => (is=>'rw',isa=>'Int',required=>1);
has 'symbol' => (is=>'rw',isa=>'Str',required=>1,default=>'@');
has 'color' => (is=>'rw',isa=>'Str',required=>1,default=>'bold blue');
has 'place' => (is=>'rw',isa=>'Place');
has 'tile' => (is=>'rw',isa=>'Place::Tile');

sub move_to {
    my ($self,$x,$y) = @_;
    return unless $self->place->chart->[$y][$x]->vasru();
    $self->tile->remove($self) if $self->tile;
    $self->x($x);
    $self->y($y);
    $self->tile($self->place->chart->[$y][$x]);
    $self->tile->add($self);
}

1;
