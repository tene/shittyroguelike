package Place;

use Place::Tile;
use Entrance;

use Moose;
use MooseX::Storage;

use Perl6::Attributes;
use Perl6::Subs;

use Object;
use Player;
use Entrance;

use Data::Dumper;

with Storage('io' => 'StorableFile');

has chart => (is=>'rw',isa=>'ArrayRef[ArrayRef[Place::Tile]]');
has objects => (is=>'rw',isa=>'HashRef');

my $constructors = {
    Object => sub {Object->new(@_)},
    Player => sub {Player->new(@_)},
    Entrance => sub {Entrance->new(@_)},
};

method BUILD ($params) {
    $.objects = {};
}

method tile ($x,$y) {
    # No negatives!
    $x = $x > 0 ? $x : 0;
    $y = $y > 0 ? $y : 0;
    $.chart->[$y]->[$x];
}

method insert ($obj) {
    $.objects->{$obj->id} = $obj;
    $.chart->[$obj->y]->[$obj->x]->enter($obj);
}

method save ($map) {
    $self->store("store/$map.storable");
}

method get ($map) {
    if (-f "store/$map.storable") {
        my $new = Place->load("store/$map.storable");
        $self->chart($new->chart);
        for my $row (@{$new->chart}) {
            for my $tile (@$row) {
                for my $item (@{$tile->contents}) {
                    $self->{objects}->{$item->id} = $item;
                }
            }
        }
    }
    elsif (-f "maps/$map.txt") {
        local $/;
        open FILE, '<:utf8', "maps/$map.txt";
        my $text = <FILE>;
        close FILE;
        $self->load_from_ascii($text);
        $self->save($map);
    }
    else {
        die "Could not load map $map";
    }
}

method load_from_ascii ($map) {
    my $a = [];
    my $y = 0;
    for (split /\n/, $map) {
        chomp;
        my @chars = split //,$_;
        my @tiles = ();
        my $x = 0;
        for my $char (@chars) {
	    # Pick a type based on the symbol in the file
	    my $type = 'ground';
	    if( $char eq '#' )
	    {
		$type = 'rock';
	    }
	    if( $char eq ' ' )
	    {
		$type = 'none';
	    }
            my $tile = Place::Tile->new(type=>$type,symbol=>$char,x=>$x,y=>$y,fg=>'white',bg=>'black',place=>$self);
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

            push @tiles, $tile;
            $x++;
        }
        push @$a, [@tiles];
        $y++;
    }

    $.chart = $a;
    ./insert(Entrance->new(
                symbol => '<',
                fg     => 'blue',
                bg     => 'black',
                x      => 5,
                y      => 5,
            ));
}

method to_ref {
    my $ref = ();
    for my $line (@{$self->chart}) {
        my @tiles = map {$_->to_hash} @$line;
        push @$ref, \@tiles;
    }
    return $ref;
}

method load_from_ref ($map) {
    my $a = [];
    my $y = 0;
    for (@$map) {
        my @items = @$_;
        my @tiles = ();
        my $x = 0;
        for my $item (@items) {
            my $char = $item->{symbol};
            my $fg = $item->{fg};
            my $bg = $item->{bg};
            my $vasru = $item->{vasru};
            my $type = $item->{type};
            my $tile = Place::Tile->new(type=>$type,symbol=>$char,x=>$x,y=>$y,fg=>$fg,bg=>$bg,place=>$self,vasru=>$vasru);

            for my $thing (@{$item->{contents}}) {
                my ($classname) = delete $thing->{class};
                my $new = $constructors->{$classname}->(%$thing);
                $tile->enter($new);
                $self->objects->{$new->id} = $new;
            }

            push @tiles, $tile;
            $x++;
        }
        push @$a, [@tiles];
        $y++;
    }

    $.chart = $a;
    ./insert(Entrance->new(
                symbol => '<',
                fg     => 'blue',
                bg     => 'black',
                x      => 5,
                y      => 5,
            ));
}

1;
