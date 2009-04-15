use Test::More tests => 16;

use lib '../lib/';

use Place;

#*******************************************
# Tests basic building placement
#*******************************************

sub tests {
    my $listener = shift;

    use FindBin qw($Bin);
    chdir "$Bin";
    print "pwd: ".`pwd`;
    unlink "store/*";
    my $fake_map = Place->new();
    $fake_map->get("test1");
    $fake_map = $fake_map->to_ref();
    #print "map: ".Dumper(\$fake_map)."\n";

    client_expect("Username", "expect 'username'");

    client_expect( "OK", "expect 'OK'" );

# Send the user name
    client_key_send("test user\n");
    sleep 1;
    client_key_send("\n");
    sleep 1;

# Get the client connection
    my $tcp_to_client = get_client( $listener );

    client_expect( "login", "expect 'login'" );

# print "Done waiting.\n";

    yaml_cmp_deeply( $tcp_to_client, "Client tcp: expecting login command", 'login', 'test user' );

    tcp_send( $tcp_to_client,
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
    client_key_send("w");
    client_key_send("\n");

    client_expect( "Eris", "expect 'Eris'" );
    client_key_send("e");
    client_key_send("\n");

    client_expect( "yellow", "expect 'yellow'" );
    client_key_send("g");
    client_key_send("\n");

# print "Done character creation.\n";

# input: register, aoeusnth Race1 God2 green
    yaml_cmp_deeply( $tcp_to_client, "Client tcp: Expecting register command",
	    'register', 'test user', 'weeble', 'Eris', 'green' );

    tcp_send( $tcp_to_client, "new_map", $fake_map );

    tcp_send( $tcp_to_client, "assign_id", 3 );

    print "Expecting add_player; takes a while.\n";
    yaml_cmp_deeply( $tcp_to_client, "Client tcp: expecting add_player command",
	    'add_player', 3, 'test user' );

    tcp_send( $tcp_to_client, "announce", q{'Arrival message.'} );

    tcp_send( $tcp_to_client, "add_player", 3,
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

    # Test failed placement, since the building won't be in a valid
    # place
    client_key_send("b");
    client_expect( "Please place the building.", "expect placement request" );
    client_key_send("\n");

    # Not the whole string because curses does something weird.
    client_expect( "Invalid building locat", "expect complaint due to building location" );

    # Test correct placement
    client_key_send("l");
    client_key_send("\n");
    client_expect( "Building placed.", "expect placement confirmation." );


    # place_building has type, x and y of upper left
    yaml_cmp_deeply( $tcp_to_client, "Client tcp: expecting place building command",
	    'place_building', 'farm', 6, 5 );

# FIXME
#    tcp_send( $tcp_to_client, "drop_item",
#	    {
#	    "class" => "Object",
#	    "type" => "farm",
#	    "id" => 1000,
#	    "symbol" => "FFF\n000\nFFF",
#	    "size_x" => 3,
#	    "size_y" => 3,
#	    "x" => 8,
#	    "y" => 8,
#	    }
#	    );
#
#    client_expect( "FFF", "expect the farm itself, part 1" );
#    client_expect( "000", "expect the farm itself, part 2" );
#    client_expect( "FFF", "expect the farm itself, part 3" );

    client_key_send("q");

# input: remove_object, 3

    yaml_cmp_deeply( $tcp_to_client, "Client tcp: expecting remove_object command",
	    'remove_object', 3 );

    tcp_send( $tcp_to_client, "remove_object", 3 );

    client_not_expect( "aeouaoeueaou", "Expect dead connection." );
};

1;
