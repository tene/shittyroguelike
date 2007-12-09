package UI::Drawable;

use Moose::Role;
use Perl6::Attributes;
use Perl6::Subs;

has 'tile' => (is=>'rw',isa=>'Place::Tile',required=>1);
has 'symbol' => (is=>'rw',isa=>'Str',required=>1);
has 'color' => (is=>'rw');

method draw {
    $.tile->draw();
}

1;
