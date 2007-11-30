package Place;

use Place::Tile;

use Moose;

use Data::Dumper;

has chart => (is=>'rw',isa=>'ArrayRef[ArrayRef[Place::Tile]]');

sub load {
    my ($self,$filename) = @_;
    open (MAP, "<:utf8", $filename);

    my $a = [];
    while (<MAP>) {
        chomp;
        my @chars = split //,$_;
        my @tiles = ();
        for my $char (@chars) {
            my $tile = Place::Tile->new();
            $tile->symbol($char);
            if($char eq '.') {
                $tile->vasru(1);
                $tile->color('bold black');
            }
            else {
                $tile->vasru(0);
                $tile->color('bold white');
            }
            push @tiles, $tile;
        }
        push @$a, [@tiles];
    }

    $self->chart($a);
}

1;
