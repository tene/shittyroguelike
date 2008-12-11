use Test::More tests => 7;
use Test::Deep;

print "In async.\n";

server_tcp_send( 'login', 'test user' );

# input: create_player, create new character HASH(0x29a6388) ARRAY(0x29a8e40) HASH(0x29a63d0)

server_tcp_test( "Expecting player creation message",
	'create_player',
	"create new character",
	superhashof( { 'Eris' => ignore() } ),
	superbagof( 'red' ),
	superhashof( { 'human' => ignore() } ),
	);

server_tcp_send( 'register', 'test user', 'human', 'bob', 'yellow' );

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

server_tcp_test( "Expecting map",
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

server_tcp_test( "Expecting userid", "assign_id", 3 );

server_tcp_send( 'add_player', 3, 'test user' );


server_tcp_test( "Expecting announcement.",
	"announce",
	re( qr{^.*, a loyal follower of .*, has arrived.} ) );

server_tcp_test( "Expecting player add.",
	"add_player", 3,
	superhashof(
	    {
	    "class" => "Player",
	    "username" => "test user",
	    },
	    ),
	5, 5, );

server_tcp_send( 'player_move_rel', 0, -1 );

server_tcp_test( "Expecting object move", "object_move_rel", 3, 0, -1 );

server_tcp_send( 'remove_object', 3 );

server_tcp_test( "Expect remove object", "remove_object", 3 );

server_exit;
