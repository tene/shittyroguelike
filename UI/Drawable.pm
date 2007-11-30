package UI::Drawable;

use Moose::Role;

has 'scr' => (is=>'rw',isa=>'UI');
has 'symbol' => (is=>'rw',isa=>'Str',required=>1);
has 'color' => (is=>'rw',isa=>'Str',required=>1,default=>'white');
