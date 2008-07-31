package Player;

use Moose;
use Perl6::Attributes;
use Perl6::Subs;

with 'UI::Drawable';

has 'username' => (is=>'rw',isa=>'Str');

method BUILD ($params) {
    $params->{'tile'}->enter($self) if $params->{'tile'};
}

method move_to ($dest) {
    return unless $dest->vasru();
    $.tile->leave($self) if $.tile;
    $.tile = $dest;
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
