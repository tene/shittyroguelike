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

sub move_rel {
    my ($self,$x,$y) = @_;
    my $dest = $self->tile;

    my $xdir = ($x < 0)? 'left' : 'right';
    my $ydir = ($y < 0)? 'up' : 'down';

    $x = abs $x;
    $y = abs $y;

    while ($x-- > 0) {
        $dest = $dest->$xdir || return;
    }

    while ($y-- > 0) {
        $dest = $dest->$ydir || return;
    }

    return unless $dest->vasru();

    $self->tile->leave($self) if $self->tile;
    $dest->enter($self);
    $self->tile($dest);

}

1;
