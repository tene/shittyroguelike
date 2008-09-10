package Player;

use Moose;
use Perl6::Attributes;
use Perl6::Subs;

with 'UI::Drawable';
with 'Actor::Alive';

has 'username' => (is=>'rw',isa=>'Str');

method BUILD ($params) {
    $params->{'tile'}->enter($self) if $params->{'tile'};
}

method death {
    my ($origin) = grep {(ref $_) eq 'Entrance'} values %{$self->tile->place->objects};
    $self->cur_hp($self->max_hp);
    $self->move_to_id($origin->id);

    return {'cur_hp'=>$self->max_hp,'move_to_id'=>$origin->id};
}
1;
