package Place;

use Place::Tile;

use Moose;

use Perl6::Attributes;
use Perl6::Subs;

use Data::Dumper;

has chart => (is=>'rw',isa=>'ArrayRef[ArrayRef[Place::Tile]]');

method load ($map,$panel,$ui) {
    $map =~ s/s/ /g;
    $map =~ s/n/\n/g;
    $map = unpack('u*',$map);
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
            my $tile = Place::Tile->new(symbol=>$char,x=>$x,y=>$y,panel=>$panel,color=>$ui->colors->{'white'}->{'black'});
            if($char eq '.') {
                $tile->vasru(1);
            }
            else {
                $tile->vasru(0);
            }
            if($char eq '#') {
                $tile->color($ui->colors->{green}->{black});
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
}

1;
