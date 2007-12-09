package Player;

use Moose;
use Perl6::Attributes;
use Perl6::Subs;

has 'place' => (is=>'rw',isa=>'Place');
has 'tile' => (is=>'rw',isa=>'Place::Tile');
has 'symbol' => (is=>'rw',isa=>'Str');
has 'color' => (is=>'rw',isa=>'Str');

method move_to ($x,$y) {
    return unless $.place->chart->[$y][$x]->vasru();
    $.tile->leave($self) if $.tile;
    $.tile = $.place->chart->[$y][$x];
    $.tile->enter($self);
}

method move_rel ($x,$y) {
    my $dest = $.tile;

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

    $.tile->leave($self) if $.tile;
    $dest->enter($self);
    $self->tile($dest);

}

1;
