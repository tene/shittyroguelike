package Place::Tile;

use Moose;
use Perl6::Attributes;
use Perl6::Subs;

has panel        => (is=>'rw',isa=>'Curses::Panel',required=>1);
has x            => (is=>'rw',isa=>'Int',required=>1);
has y            => (is=>'rw',isa=>'Int',required=>1);
has vasru        => (is=>'rw',isa=>'Bool');
has contents     => (is=>'rw',isa=>'ArrayRef[Object]',auto_deref=>1);
has floor_symbol => (is=>'rw',isa=>'Str');
has floor_color  => (is=>'rw',isa=>'Str');
has left         => (is=>'rw',isa=>'Place::Tile');
has right        => (is=>'rw',isa=>'Place::Tile');
has up           => (is=>'rw',isa=>'Place::Tile');
has down         => (is=>'rw',isa=>'Place::Tile');
has 'symbol' => (is=>'rw',isa=>'Str',required=>1);
has 'color' => (is=>'rw');
   
method draw {
    $.panel->panel_window->attron($.color);
    $.panel->panel_window->addstr($.y,$.x,$.symbol);
    $.panel->panel_window->attroff($.color);
}
 

method BUILD ($params) {
    $.floor_symbol = $params->{'symbol'};
    $.floor_color = $params->{'color'} || undef;
}

method enter ($obj) {
    $obj->tile($self);

    $.symbol = $obj->symbol;
    $.color = $obj->color;
    ./add($obj);
    ./draw();
}

method leave ($obj) {
    ./remove($obj);
    my @l = ./contents;
    if(@l) {
        $.symbol = $l[-1]->symbol;
        $.color = $l[-1]->color;
    }
    else {
        $.symbol = $.floor_symbol;
        $.color = $.floor_color;
    }
    ./draw();
}

method remove ($obj) {
    $.contents = [grep {! $_->id == $obj->id} ./contents()];
}

method add ($obj) {
    $.contents = [./contents(), $obj];
}

1;