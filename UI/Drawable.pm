package UI::Drawable;

use Moose::Role;
use Term::ANSIColor;

has 'scr' => (is=>'rw',isa=>'Term::Screen');
has 'symbol' => (is=>'rw',isa=>'Str',required=>1);
has 'color' => (is=>'rw',isa=>'Str',required=>1,default=>'white');
has 'x' => (is=>'rw',isa=>'Int',required=>1);
has 'y' => (is=>'rw',isa=>'Int',required=>1);

sub draw {
    my $self = shift;

    print color $self->color;
    $self->scr->at($self->y,$self->x)->puts($self->symbol);

}
