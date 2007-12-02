package Place;

use Place::Tile;

use Moose;

use Data::Dumper;

has chart => (is=>'rw',isa=>'ArrayRef[ArrayRef[Place::Tile]]');

sub load {
    my ($self,$filename,$panel) = @_;
    open (MAP, "<:utf8", $filename);

    my $a = [];
    my $y = 0;
    my $prevline;
    while (<MAP>) {
        chomp;
        my @chars = split //,$_;
        my @tiles = ();
        my $x = 0;
        my $prevtile;
        for my $char (@chars) {
            my $tile = Place::Tile->new(symbol=>$char,x=>$x,y=>$y,panel=>$panel);
            if($char eq '.') {
                $tile->vasru(1);
                $tile->color('bold black');
            }
            else {
                $tile->vasru(0);
                $tile->color('bold black');
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

    $self->chart($a);
}

1;
