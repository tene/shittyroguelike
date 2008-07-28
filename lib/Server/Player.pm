package Server::Player;

use Moose;

has 'id'     => (isa => 'Int', is => 'rw');
has 'symbol' => (isa => 'Str', is => 'rw');
has 'fg'     => (isa => 'Str', is => 'rw');
has 'bg'     => (isa => 'Str', is => 'rw');
has 'y'      => (isa => 'Int', is => 'rw');
has 'x'      => (isa => 'Int', is => 'rw');

1;
