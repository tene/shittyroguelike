package Place::Thing;

use Moose;

with 'UI::Drawable';

sub to_hash {
    my $self = shift;
    my %hash = map {$_ => $self->$_} qw/symbol fg bg id/;
    $hash{class} = 'Thing';
    return \%hash;
}

1;
