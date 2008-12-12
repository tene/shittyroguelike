use Test::More tests => 13;

sub tests {
    my $listener = shift;

# Get the client talking to the server.
    client_expect("Username", "expect 'username'");

    client_expect( "OK", "expect 'OK'" );

# Send the user name
    client_key_send("test user\n");
    sleep 1;
    client_key_send("\n");
    sleep 1;

    print "getting tpc client.\n";
# Get the client connection
    my $tcp_to_client = get_client( $listener );
    print "done getting tpc client.\n";

    client_expect( "login", "expect 'login'" );

# print "Done waiting.\n";

    yaml_cmp_deeply( $tcp_to_client,
	    "Client tcp: expecting login command",
	    'login', 'test user',
	    );

    tcp_send(
	    $tcp_to_client,
	    "create_player",
	    "create new character",
	    {
	    "Eris" => { "desc" => "god desc1", },
	    "bob" => { "desc" => "god desc2", },
	    },
	    [ "red", "green", "yellow", ],
	    {
	    "human" => { "desc" => "race desc1", },
	    "weeble" => { "desc" => "race desc2", },
	    },
	    );

    client_expect( "human", "expect 'human'" );
    client_key_send("h");
    client_key_send("\n");

    client_expect( "Eris", "expect 'Eris'" );
    client_key_send("b");
    client_key_send("\n");

    client_expect( "yellow", "expect 'yellow'" );
    client_key_send("y");
    client_key_send("\n");

# print "Done character creation.\n";

# input: register, aoeusnth Race1 God2 green
    yaml_cmp_deeply( $tcp_to_client,
	    "Client tcp: Expecting register command",
	    'register', 'test user', 'human', 'bob', 'yellow',
	    );

    my $fake_map =
	[
	[
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	],
	[
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	],
	[
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	],
	[
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	],
	[
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	],
	[
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	{
	    "bg" => "black",
	    "contents" => [],
	    "fg" => "white",
	    "symbol" => '.',
	    "vasru" => 0,
	},
	],
	];

    tcp_send(
	    $tcp_to_client,
	    "new_map", $fake_map );

    tcp_send(
	    $tcp_to_client,
	    "assign_id", 3 );

# print "about to announce.\n";

# input: add_player, 3 aoesuntahoeu

    yaml_cmp_deeply( $tcp_to_client,  "Client tcp: expecting add_player command",
	    'add_player', 3, 'test user' );

    tcp_send(
	    $tcp_to_client,
	    "announce", q{'Arrival message.'} );

    tcp_send(
	    $tcp_to_client,
	    "add_player", 3,
	    {
	    "bg" => "black",
	    "class" => "Player",
	    "cur_hp" => "130",
	    "eyes" => "13",
	    "fg" => "red",
	    "id" => "3",
	    "limbs" => "13",
	    "max_hp" => "130",
	    "muscle" => "13",
	    "organs" => "13",
	    "physical" => "13",
	    "practical" => "13",
	    "scholarly" => "13",
	    "social" => "13",
	    "symbol" => '@',
	    "username" => "test user",
	    },
	    5, 5, );

    client_expect( "announce", "expect 'announce'" );

    client_key_send("k");

# input: player_move_rel, 0 -1

    yaml_cmp_deeply( $tcp_to_client,  "Client tcp: expecting player_rel command",
	    'player_move_rel', 0, -1 );

    tcp_send(
	    $tcp_to_client,
	    "object_move_rel", 3, 0, -1 );

    client_key_send("q");

# input: remove_object, 3

    yaml_cmp_deeply( $tcp_to_client,  "Client tcp: expecting remove_object command",
	    'remove_object', 3 );

    tcp_send(
	    $tcp_to_client,
	    "remove_object", 3 );

    client_not_expect( "aeouaoeueaou", "Expect dead connection." );

};

1;
