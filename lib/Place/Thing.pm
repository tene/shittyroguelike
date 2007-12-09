package Place::Thing;

use Moose;

has symbol => (is=>'rw',isa=>'Str',required=>1);
has color => (is=>'rw',isa=>'Str',required=>1,default=>'white');

1;
