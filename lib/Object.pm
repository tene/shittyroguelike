package Object;

use Moose;
use MooseX::Storage;
use Perl6::Attributes;
use Perl6::Subs;

with Storage('io' => 'StorableFile');
my $counter = 0;

has 'x' => (is=>'rw',isa=>'Int');
has 'y' => (is=>'rw',isa=>'Int');
has 'symbol' => (is=>'rw',default=>'@');
has 'fg' => (is=>'rw');
has 'bg' => (is=>'rw');
has 'id' => (is=>'rw',isa=>'Int',required=>1,default=>sub {1000 + $counter++});

method to_hash {
    my %hash = map { $_ => $self->$_ } qw/symbol fg bg id x y/;
    $hash{class} = 'Object';
    return \%hash;
}

method clear {
    $.tile->leave($self);
}

1;
