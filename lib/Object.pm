package Object;

use Moose;
use Perl6::Attributes;
use Perl6::Subs;

my $counter = 0;

has 'tile' => (is=>'rw',isa=>'Place::Tile');
has 'symbol' => (is=>'rw',default=>'@');
has 'fg' => (is=>'rw');
has 'bg' => (is=>'rw');
has 'id' => (is=>'rw',isa=>'Int',required=>1,default=>sub {1000 + $counter++});

method to_hash {
    my %hash = map { $_ => $self->$_ } qw/symbol fg bg id/;
    $hash{class} = 'Object';
    return \%hash;
}

method clear {
    $.tile->leave($self);
}

method move_to_id ($id) {
    my $dest = $self->tile->place->objects->{$id}->tile;

    $.tile->leave($self);
    $dest->enter($self);
}

1;
