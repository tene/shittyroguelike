package Entrance;

use Moose;
use Perl6::Attributes;
use Perl6::Subs;

extends 'Object';

sub to_hash {
    my $self = shift;
    my %hash = map {$_ => $self->$_} qw/symbol fg bg id/;
    $hash{class} = 'Entrance';
    return \%hash;
}

1;
