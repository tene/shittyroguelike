package Place::Tile;

use Moose;

with 'UI::Drawable';

has vasru => (is=>'rw',isa=>'Bool');
has contents => (is=>'rw',isa=>'ArrayRef[Object]',auto_deref=>1);
has floor_symbol => (is=>'rw',isa=>'Str');

sub BUILD {
    my ($self,$params) = @_;
    $self->floor_symbol($params->{'symbol'});
}

sub enter {
    my $self = shift;
    my $obj = shift;

    $obj->tile($self);

    $self->symbol($obj->symbol);
    $self->add($obj);
    $self->draw();
}

sub leave {
    my ($self,$obj) = @_;
    $self->remove($obj);
    my @l = $self->contents();
    if(@l) {
        $self->symbol($self->contents->[-1]->symbol );
    }
    else {
        $self->symbol($self->floor_symbol);
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
