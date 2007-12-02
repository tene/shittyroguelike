package Place;

use Place::Tile;

use Moose;

use Data::Dumper;

has chart => (is=>'rw',isa=>'ArrayRef[ArrayRef[Place::Tile]]');

sub load {
    my ($self,$filename,$scr) = @_;
    open (MAP, "<:utf8", $filename);

    my $a = [];
    my $y = 0;
    while (<MAP>) {
        chomp;
        my @chars = split //,$_;
        my @tiles = ();
        my $x = 0;
        for my $char (@chars) {
            my $tile = Place::Tile->new(symbol=>$char,x=>$x,y=>$y,scr=>$scr);
            if($char eq '.') {
                $tile->vasru(1);
                $tile->color('bold black');
            }
            else {
                $tile->vasru(0);
                $tile->color('bold white');
            }
            push @tiles, $tile;
            $x++;
        }
        push @$a, [@tiles];
        $y++;
    }

    $self->chart($a);
}

1;
