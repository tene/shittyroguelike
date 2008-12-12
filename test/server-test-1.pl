use Test::More tests => 7;

sub tests {

    my $tcp_to_server = make_client();

    tcp_send( $tcp_to_server, 'login', 'test user' );

# input: create_player, create new character HASH(0x29a6388) ARRAY(0x29a8e40) HASH(0x29a63d0)

    yaml_cmp_deeply( 
	    $tcp_to_server,
	    "Expecting player creation message",
	    'create_player',
	    "create new character",
	    superhashof( { 'Eris' => ignore() } ),
	    superbagof( 'red' ),
	    superhashof( { 'human' => ignore() } ),
	    );

    tcp_send( $tcp_to_server, 'register', 'test user', 'human', 'bob', 'yellow' );

#input: new_map, $VAR1 = [
#          [
#            [
#              {
#                'symbol' => ' ',
#                'vasru' => '0',
#                'contents' => [],
#                'fg' => 'white',
#                'bg' => 'black'
#              },

    yaml_cmp_deeply(
	    $tcp_to_server,
	    "Expecting map",
	    "new_map",
	    superbagof(
		superbagof(
		    {
		    'symbol' => ignore(),
		    'vasru' => ignore(),
		    'contents' => ignore(),
		    'fg' => ignore(),
		    'bg' => ignore(),
		    },
		    )
		)
	    );


#input: assign_id, $VAR1 = [
#          '3'
#        ];

    yaml_cmp_deeply( $tcp_to_server, "Expecting userid", "assign_id", 3 );

    tcp_send( $tcp_to_server, 'add_player', 3, 'test user' );


    yaml_cmp_deeply( $tcp_to_server, "Expecting announcement.",
	    "announce",
	    re( qr{^.*, a loyal follower of .*, has arrived.} ) );

    yaml_cmp_deeply( $tcp_to_server, "Expecting player add.",
	    "add_player", 3,
	    superhashof(
		{
		"class" => "Player",
		"username" => "test user",
		},
		),
	    5, 5, );

    tcp_send( $tcp_to_server, 'player_move_rel', 0, -1 );

    yaml_cmp_deeply( $tcp_to_server, "Expecting object move", "object_move_rel", 3, 0, -1 );

    tcp_send( $tcp_to_server, 'remove_object', 3 );

    yaml_cmp_deeply( $tcp_to_server, "Expect remove object", "remove_object", 3 );

    server_exit;

};

1;
