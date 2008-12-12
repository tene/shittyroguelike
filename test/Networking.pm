=head1 Networking

Helper bits for the testing software.  Mostly pretty retarded, but
if it's encapsulated here then it's easy to change later.

=cut

use Data::Dumper;

use ManualExpect;

use IO::Socket;

use YAML;

use Test::Deep;

=head2 C<make_server>

Makes a TCP listener on port 3456.

=cut
sub make_server
{
    return IO::Socket::INET->new(
	Listen => 5,
	LocalAddr => 'localhost',
	LocalPort => 3456,
	Proto =>'tcp',
	Blocking => 1,
	ReuseAddr => 1,
	);
};

=head2 C<get_client>

Pass a server from make_server; blocks until a client connects,
returns an IO::Socket handle to the client.

=cut
sub get_client
{
    my $listener = shift;

    # print "getting client: ".Dumper(\$listener).".\n";

    $listener->timeout(999);

    # print "Done timeout.\n";

    my $client = $listener->accept();

    # print "client: $client.\n";

    return $client;
};

=head2 C<make_client>

Makes a TCP connection to the server on port 3456.

=cut
sub make_client
{
    my $client;
    while( ! defined $client )
    {
	sleep 1;

	$client = IO::Socket::INET->new(
		PeerHost => 'localhost',
		PeerPort => 3456,
		Proto =>'tcp',
		Blocking => 1,
		ReuseAddr => 1,
		Timeout => 999,
		);
    }

    return $client;

};

=head2 C<get_yaml>

Given an IO::Socket handle, blocks until a valid YAML request comes
in.

=cut
sub get_yaml {
    my $socket = $_[0];
    my $byte = 1;
    my $data = '';
    my $size = '';

    do {
	$socket->read( $byte, 1 );
	$size .= $byte;

	# print "byte: -".Dumper(\$byte)."-.\n";
	# print "size: -".Dumper(\$size)."-.\n";
    } while( ord($byte) != 0 );

    # print "size: -".Dumper(\$size)."-.\n";

    $socket->read( $data, $size );

    # print "data: -".Dumper(\$data)."-.\n";

    my $stuff = Load( $data );

    # print "stuff: ".Dumper(\$stuff)."\n";

    return $stuff;
};


=head2 C<get_yaml>

Given an IO::Socket handle, sends data out it using YAML formatting.

=cut
sub tcp_send{
    my $socket = shift;

    my $yaml = Dump( [ @_ ] );
    my $size = length $yaml;

    $socket->print( "$size\0$yaml" );
};

=head2 C<yaml_cmp_deeply>

Given an IO::Socket handle, runs get_yaml on it, and compares the
results to the expected with Test::Deep

Args; note the order is different from the normal test functions:

    socket

    test string

    expected (rest of array)

=cut
sub yaml_cmp_deeply {
    my $socket = shift;
    my $desc = shift;
    my $actual = get_yaml( $socket );

    # print "in yaml_cmp_deeply, actual: ".Dumper(\$actual)."\n";

    cmp_deeply(
	    $actual,
	    [ @_ ],
	    $desc
    );
};

=head2 C<yaml_cmp_deeply_debug>

See above; debug version.

=cut
sub yaml_cmp_deeply_debug {
    my $socket = shift;
    my $desc = shift;
    my $actual = get_yaml( $socket );

    print "in yaml_cmp_deeply debug, actual: ".Dumper(\$actual)."\n";

    cmp_deeply(
	    $actual,
	    [ @_ ],
	    $desc
    );
};

1;
