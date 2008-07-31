package Server::Player;

use Moose;

has 'id'       => (isa => 'Int', is => 'rw');
has 'symbol'   => (isa => 'Str', is => 'rw');
has 'fg'       => (isa => 'Str', is => 'rw');
has 'bg'       => (isa => 'Str', is => 'rw');
has 'tile'     => (isa => 'HashRef', is => 'rw');
has 'username' => (isa => 'Str', is => 'rw');

1;
