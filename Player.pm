package Player;

use Moose;

has 'x' => (is=>'rw',isa=>'Int',required=>1);
has 'y' => (is=>'rw',isa=>'Int',required=>1);
has 'char' => (is=>'rw',isa=>'Str',required=>1,default=>'∂');
has 'color' => (is=>'rw',isa=>'Str',required=>1,default=>'bold blue');
has 'place' => (is=>'rw',isa=>'Place');

sub move_to {
    my ($self,$x,$y) = @_;
    return if $self->place->chart->[$y][$x] eq '#';
    $self->x($x);
    $self->y($y);
}

1;
