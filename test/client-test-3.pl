
use Test::More tests => 12;

client_expect("Username", "expect 'username'");

client_expect( "OK", "expect 'OK'" );

# Send the user name
client_key_send("test user\n");
sleep 1;
client_key_send("\n");
sleep 1;

client_expect( "login", "expect 'login'" );

# print "Done waiting.\n";

test_client_tcp( "Client tcp: expecting login command", 'login', 'test user' );

client_tcp_send(
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
test_client_tcp( "Client tcp: Expecting register command",
	'register', 'test user', 'weeble', 'Eris', 'green' );

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

client_tcp_send( "new_map", $fake_map );

client_tcp_send( "assign_id", 3 );

# print "about to announce.\n";

# input: add_player, 3 aoesuntahoeu

test_client_tcp( "Client tcp: expecting add_player command",
	'add_player', 3, 'test user' );

client_tcp_send( "announce", q{'Arrival message.'} );

client_tcp_send( "add_player", 3,
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

client_key_send("d");

# - drop_item
# - '*'
# - red
# - black
# 
# 00:25:20.351065 IP localhost.3456 > localhost.33142: P 75621:75721(100) ack 151 win 256 <nop,nop,timestamp 539735577 539735573>
# ..v&..c&.. ...........
#  +.. +..97.---
# - drop_item
# - 3
# - bg: black
#   class: Object
#   fg: red
#   id: 1000
#   symbol: '*'
#   x: 5
#   y: 5


# input: drop_item, '*', red, black

test_client_tcp( "Client tcp: expecting drop item command",
	'drop_item', '*', 'red', 'black' );

client_tcp_send( "drop_item", 3,
	{
	    "bg" => "black",
	    "class" => "Object",
	    "fg" => "red",
	    "id" => 1000,
	    "symbol" => "*",
	    "x" => 5,
	    "y" => 5,
	}
    );

client_key_send("q");

# input: remove_object, 3

test_client_tcp( "Client tcp: expecting remove_object command",
	'remove_object', 3 );

client_tcp_send( "remove_object", 3 );

client_not_expect( "aeouaoeueaou", "Expect just to wait for connection end." );
