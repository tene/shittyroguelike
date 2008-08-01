package Place::Tile;

use Moose;
use Perl6::Attributes;
use Perl6::Subs;

has x            => (is=>'rw',isa=>'Int',required=>1);
has y            => (is=>'rw',isa=>'Int',required=>1);
has vasru        => (is=>'rw',isa=>'Bool');
has contents     => (is=>'rw',isa=>'ArrayRef[Object]',auto_deref=>1);
has floor_symbol => (is=>'rw',isa=>'Str');
has floor_fg     => (is=>'rw',isa=>'Str');
has floor_bg     => (is=>'rw',isa=>'Str');
has left         => (is=>'rw',isa=>'Place::Tile');
has right        => (is=>'rw',isa=>'Place::Tile');
has up           => (is=>'rw',isa=>'Place::Tile');
has down         => (is=>'rw',isa=>'Place::Tile');
has 'symbol' => (is=>'rw',isa=>'Str',required=>1);
has 'fg'         => (is=>'rw',isa=>'Str');
has 'bg'         => (is=>'rw',isa=>'Str');
   
method BUILD ($params) {
    $.floor_symbol = $params->{'symbol'};
    $.floor_fg = $params->{'fg'} || undef;
    $.floor_bg = $params->{'bg'} || undef;
}

method enter ($obj) {
    $obj->tile($self);

    $.symbol = $obj->symbol;
    $.fg = $obj->fg;
    $.bg = $obj->bg;
    ./add($obj);
    $.vasru = 0;
}

method leave ($obj) {
    ./remove($obj);
    my @l = ./contents;
    if(@l) {
        $.symbol = $l[-1]->symbol;
        $.fg = $l[-1]->fg;
        $.bg = $l[-1]->bg;
    }
    else {
        $.symbol = $.floor_symbol;
        $.fg = $.floor_fg;
        $.bg = $.floor_bg;
    }
    $.vasru = 1;
}

method remove ($obj) {
    $.contents = [grep {$_ != $obj} ./contents()];
}

method add ($obj) {
    $.contents = [./contents(), $obj];
}

1;
