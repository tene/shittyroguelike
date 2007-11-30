package Place::Tile;

use Moose;

has symbol => (is=>'rw',isa=>'Str');
has color => (is=>'rw',isa=>'Str');
has vasru => (is=>'rw',isa=>'Bool');
has contents => (is=>'rw',isa=>'ArrayRef[Object]',auto_deref=>1);

sub remove {
    my $self = shift;
    my $obj = shift;

    $self->contents(grep {$_ != $obj} $self->contents);
}

sub add {
    my $self = shift;
    my $obj = shift;

    $self->contents([$self->contents(), $obj]);
}
1;
