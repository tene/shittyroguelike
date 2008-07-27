package UI::Drawable;

use Moose::Role;
use Perl6::Attributes;
use Perl6::Subs;

my $counter = 0;

has 'tile' => (is=>'rw',isa=>'Place::Tile');
has 'symbol' => (is=>'rw',isa=>'Str',required=>1);
has 'color' => (is=>'rw');
has 'id' => (is=>'rw',isa=>'Int',required=>1,default=>sub {1000 + $counter++});

method draw {
    $.tile->draw();
}

method clear {
    $.tile->leave($self);
    $.tile->draw();
}

1;
