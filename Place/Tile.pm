package Place::Tile;

use Moose;

with 'UI::Drawable';

has vasru        => (is=>'rw',isa=>'Bool');
has contents     => (is=>'rw',isa=>'ArrayRef[Object]',auto_deref=>1);
has floor_symbol => (is=>'rw',isa=>'Str');
has floor_color  => (is=>'rw',isa=>'Str');
has left         => (is=>'rw',isa=>'Place::Tile');
has right        => (is=>'rw',isa=>'Place::Tile');
has up           => (is=>'rw',isa=>'Place::Tile');
has down         => (is=>'rw',isa=>'Place::Tile');

sub BUILD {
    my ($self,$params) = @_;
    $self->floor_symbol($params->{'symbol'});
    $self->floor_color($params->{'color'} || 'bold black');
}

sub enter {
    my $self = shift;
    my $obj = shift;

    $obj->tile($self);

    $self->symbol($obj->symbol);
    $self->color($obj->color);
    $self->add($obj);
    $self->draw();
}

sub leave {
    my ($self,$obj) = @_;
    $self->remove($obj);
    my @l = $self->contents();
    if(@l) {
        $self->symbol($self->contents->[-1]->symbol );
        $self->color($self->contents->[-1]->color );
    }
    else {
        $self->symbol($self->floor_symbol);
        $self->color($self->floor_color);
    }
    $self->draw();
}

sub remove {
    my $self = shift;
    my $obj = shift;

    $self->contents([grep {$_->symbol() ne $obj->symbol()} $self->contents]);
}

sub add {
    my $self = shift;
    my $obj = shift;

    $self->contents([$self->contents(), $obj]);
}
1;
