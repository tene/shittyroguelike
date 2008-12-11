
# This is a special test: it gets run with the --user command line
# arg for the client.

use Test::More tests => 12;

client_expect( "login", "expect 'login'" );

# print "Done waiting.\n";

test_client_tcp( "Client tcp: expecting login command", 'login', 'rlpowell' );

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
	'register', 'rlpowell', 'weeble', 'Eris', 'green' );

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
	'add_player', 3, 'rlpowell' );

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
	"username" => "rlpowell",
	},
	5, 5, );

client_expect( "announce", "expect 'announce'" );

# Add another (fake) player
client_tcp_send( "add_player", 4,
	{
	"bg" => "red",
	"class" => "Player",
	"cur_hp" => "130",
	"eyes" => "13",
	"fg" => "black",
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
	"username" => "weeeble",
	},
	4, 5, );

client_expect_re( "weeeble.@.* 130/130", "expect fake player" );

# Not bound to anything; nothing should happen.
client_key_send("x");

client_key_send("k");

test_client_tcp( "Client tcp: expecting real player attack command",
	"attack", 4, 0, -1 );

client_tcp_send( "change_object", "3", { "cur_hp", 98 } );

client_expect( "98/130", "expect changed hp" );

client_tcp_send( "remove_object", 4 );

client_key_send("q");

# input: remove_object, 3

test_client_tcp( "Client tcp: expecting remove_object command",
	'remove_object', 3 );

client_tcp_send( "remove_object", 3 );
