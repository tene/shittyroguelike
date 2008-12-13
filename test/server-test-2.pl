use Test::More tests => 23;

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

    my $tcp_to_server2 = make_client();

    tcp_send( $tcp_to_server2, 'login', 'test user 2' );

# input: create_player, create new character HASH(0x29a6388) ARRAY(0x29a8e40) HASH(0x29a63d0)

    yaml_cmp_deeply( 
	    $tcp_to_server2,
	    "Expecting player creation message",
	    'create_player',
	    "create new character",
	    superhashof( { 'Eris' => ignore() } ),
	    superbagof( 'red' ),
	    superhashof( { 'human' => ignore() } ),
	    );

    tcp_send( $tcp_to_server2, 'register', 'test user 2', 'gremlin', 'Eris', 'green' );

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
	    $tcp_to_server2,
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

    yaml_cmp_deeply( $tcp_to_server2, "Expecting userid", "assign_id", 4 );

    tcp_send( $tcp_to_server2, 'add_player', 4, 'test user 2' );

    # Expect the announcements on the new client
    yaml_cmp_deeply( $tcp_to_server2, "Expecting announcement.",
	    "announce",
	    re( qr{^test user 2, a loyal follower of Eris, has arrived.} ) );

    yaml_cmp_deeply( $tcp_to_server2, "Expecting player add.",
	    "add_player", 4,
	    superhashof(
		{
		"class" => "Player",
		"username" => "test user 2",
		},
		),
	    5, 5, );

    # and on the original client as well.
    yaml_cmp_deeply( $tcp_to_server, "Expecting announcement.",
	    "announce",
	    re( qr{^test user 2, a loyal follower of Eris, has arrived.} ) );

    yaml_cmp_deeply( $tcp_to_server, "Expecting player add.",
	    "add_player", 4,
	    superhashof(
		{
		"class" => "Player",
		"username" => "test user 2",
		},
		),
	    5, 5, );

    # Test user 2 hitting test user
    tcp_send( $tcp_to_server2, 'attack', 3, 0, -1 );

    # Might have been a miss.
    $hit_test = get_yaml( $tcp_to_server );

    print "ht: ".Dumper(\$hit_test).".\n";

    if( $$hit_test[1] =~ m/missed/ )
    {
	cmp_deeply(
		$hit_test,
		[ 'announce',
		re('test user 2 missed.') ],
		"Expecting miss announce",
		);

	yaml_cmp_deeply_debug( $tcp_to_server2, "Expecting miss announce 2",
		'announce',
		re('test user 2 missed') );
	
	ok( 1, "Padding to deal with miss.\n");
	ok( 1, "Padding to deal with miss.\n");
    } else {
	cmp_deeply(
		$hit_test,
		[ 'announce',
		re('test user 2 hit test user for [0-9]+ damage.') ],
		"Expecting hit announce",
		);

	yaml_cmp_deeply_debug( $tcp_to_server2, "Expecting hit announce 2",
		'announce',
		re('(test user 2 hit test user for [0-9]+ damage.|test user 2 missed)') );

	yaml_cmp_deeply_debug( $tcp_to_server, "Expecting hit",
		'change_object', 3, { 'cur_hp' => num( 110, 30 ) } );

	yaml_cmp_deeply_debug( $tcp_to_server2, "Expecting hit 2",
		'change_object', 3, { 'cur_hp' => num( 110, 30 ) } );
    };

    # Test user hitting test user 2
    tcp_send( $tcp_to_server, 'attack', 4, 0, 1 );

    # Might have been a miss.
    $hit_test = get_yaml( $tcp_to_server );

    if( $$hit_test[1] =~ m/missed/ )
    {
	cmp_deeply(
		$hit_test,
		[ 'announce',
		re('test user missed.') ],
		"Expecting miss announce",
		);

	yaml_cmp_deeply_debug( $tcp_to_server2, "Expecting miss announce 2",
		'announce',
		re('test user missed') );

	ok( 1, "Padding to deal with miss.\n");
	ok( 1, "Padding to deal with miss.\n");
    } else {
	cmp_deeply(
		$hit_test,
		[ 'announce',
		re('test user hit test user 2 for [0-9]+ damage.') ],
		"Expecting hit announce",
		);

	yaml_cmp_deeply_debug( $tcp_to_server2, "Expecting hit announce 2",
		'announce',
		re('(test user hit test user 2 for [0-9]+ damage.|test user 2 missed)') );

	yaml_cmp_deeply_debug( $tcp_to_server, "Expecting hit",
		'change_object', 4, { 'cur_hp' => num( 110, 30 ) } );

	yaml_cmp_deeply_debug( $tcp_to_server2, "Expecting hit 2",
		'change_object', 4, { 'cur_hp' => num( 110, 30 ) } );
    };

    tcp_send( $tcp_to_server, 'remove_object', 3 );

    yaml_cmp_deeply( $tcp_to_server, "Expect remove object", "remove_object", 3 );

    server_exit;

};

1;
