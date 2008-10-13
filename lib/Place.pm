package Place;

use Place::Tile;
use Entrance;

use Moose;

use Perl6::Attributes;
use Perl6::Subs;

use Data::Dumper;

has chart => (is=>'rw',isa=>'ArrayRef[ArrayRef[Place::Tile]]');
has objects => (is=>'rw',isa=>'HashRef');

method BUILD ($params) {
    $.objects = {};
}

method insert ($obj,$x,$y) {
    $.objects->{$obj->id} = $obj;
    $.chart->[$y]->[$x]->enter($obj);
}

method load ($map) {
    my $a = [];
    my $y = 0;
    my $prevline;
    for (split /\n/, $map) {
        chomp;
        my @chars = split //,$_;
        my @tiles = ();
        my $x = 0;
        my $prevtile;
        for my $char (@chars) {
            my $tile = Place::Tile->new(symbol=>$char,x=>$x,y=>$y,fg=>'white',bg=>'black',place=>$self);
            if($char eq '.') {
                $tile->vasru(1);
            }
            else {
                $tile->vasru(0);
            }
            if($char eq '#') {
                $tile->fg('green');
            }
            if (ord($char) > 128) {
                $tile->fg('green');
            }

            if ($prevtile) {
                $prevtile->right($tile);
                $tile->left($prevtile);
            }
            $prevtile = $tile;

            if (defined $prevline && defined $prevline->[$x]) {
                $prevline->[$x]->down($tile);
                $tile->up($prevline->[$x]);
            }
            push @tiles, $tile;
            $x++;
        }
        $prevline = \@tiles;
        push @$a, [@tiles];
        $y++;
    }

    $.chart = $a;
    ./insert(Entrance->new(
                symbol => '<',
                fg     => 'blue',
                bg     => 'black',
            ),5,5);
}

1;
