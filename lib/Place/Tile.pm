package Place::Tile;

use Moose;
use MooseX::Storage;
use Perl6::Attributes;
use Perl6::Subs;

with Storage('io' => 'StorableFile');

has x            => (is=>'rw',isa=>'Int',required=>1);
has y            => (is=>'rw',isa=>'Int',required=>1);
has vasru        => (is=>'rw',isa=>'Bool');
has contents     => (is=>'rw',isa=>'ArrayRef[Object]',auto_deref=>1);
has 'symbol' => (is=>'rw',isa=>'Str',required=>1);
has 'fg'         => (is=>'rw',isa=>'Str');
has 'bg'         => (is=>'rw',isa=>'Str');

__PACKAGE__->meta->make_immutable;
   
method BUILD ($params) {
    $.symbol = $params->{'symbol'};
    $.fg = $params->{'fg'} || undef;
    $.bg = $params->{'bg'} || undef;
    $.contents = [];
}

method to_hash {
    my %hash = map { $_ => $self->$_ } qw/symbol fg bg vasru/;
    my @contents = map {$_->to_hash} @{$self->contents};
    $hash{contents} = \@contents;
    return \%hash;
}

method enter ($obj) {
    $obj->x($.x);
    $obj->y($.y);

    ./add($obj);
    $.vasru = 0 if (ref $obj eq 'Player');
}

method leave ($obj) {
    ./remove($obj);
    $.vasru = 1 if (ref $obj eq 'Player');
}

method remove ($obj) {
    $.contents = [grep {$_ != $obj} ./contents()];
}

method add ($obj) {
    my $top = $.contents[-1];
    if (ref $top eq 'Player') {
        my $a = pop @{$.contents};
        push @{$.contents}, ($obj, $a);
    }
    else {
        $.contents = [./contents(), $obj];
    }
}

1;
