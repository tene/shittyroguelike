package Actor::Stats;

use Moose::Role;

with 'Actor::Alive';

has 'muscle' => (is=>'rw',isa=>'Int',default=>13);
has 'organs' => (is=>'rw',isa=>'Int',default=>13);
has 'limbs' => (is=>'rw',isa=>'Int',default=>13);
has 'eyes' => (is=>'rw',isa=>'Int',default=>13);
has 'scholarly' => (is=>'rw',isa=>'Int',default=>13);
has 'practical' => (is=>'rw',isa=>'Int',default=>13);
has 'physical' => (is=>'rw',isa=>'Int',default=>13);
has 'social' => (is=>'rw',isa=>'Int',default=>13);

1;
