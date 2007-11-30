package Place;

use Moose;

has chart => (is=>'rw',isa=>'ArrayRef[ArrayRef[Str]]');

sub load {
    my ($self,$filename) = @_;
    open (MAP, "<:utf8", $filename);

    my $a = [];
    while (<MAP>) {
        chomp;
        my @chars = split //,$_;
        push @$a, [@chars];
    }

    $self->chart($a);
}

1;
