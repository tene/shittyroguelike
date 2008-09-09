package Actor::Alive;

use Moose::Role;
use Perl6::Attributes;
use Perl6::Subs;

has 'max_hp'       => (is=>'rw',isa=>'Int');
has 'cur_hp'       => (isa=>'Int');
has 'alive'        => (is=>'rw',isa=>'Bool');

method cur_hp (?$hp) {
    if (defined $hp) {
        if ($hp < 1) {
            $.cur_hp = 0;
            $.alive = 0;
        }
        else {
            $.cur_hp = $hp;
            $.alive = 1;
        }
        return $self;
    }
    else {
        return $.cur_hp;
    }
}

1;
