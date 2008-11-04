package Player;

use Moose;
use Perl6::Attributes;
use Perl6::Subs;

with 'Object';# => { alias => {to_hash => 'drawable_hash'}};
with 'Actor::Stats';# => { alias => {to_hash => 'stats_hash'}};

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

method to_hash {
    my %hash = map {$_ => $self->$_} qw/symbol fg bg id cur_hp max_hp muscle organs limbs eyes scholarly practical physical social username/;
    $hash{class} = 'Player';
    return \%hash;
};

1;
