#!/usr/bin/perl

use strict;

use FindBin::libs;

use Curses;
use POE qw(Wheel::Curses Wheel::SocketFactory Wheel::ReadWrite Driver::SysRW Filter::Reference);
use Switch 'Perl6';

use Player;
use Place;
use Place::Thing;
use UI;
use PadWalker qw(peek_my);

my @sigils = ('a'..'z', qw(
    @ & ! ~ ` ' " ? ^ _ , +
    ∂ ∫ Δ ∇ ∬ ∮ ∱ ⨑ ∲ ∳ 
    ∞ ℵ ℘ ℑ ℜ ℝ ℂ ℕ ℙ ℚ ℤ
    ƒ ′ ″ ‴ ∴ ⋅
    ⊕ ⊖ ⊗ ⊘ ⊙ ⊚ ⊛ ⊜ ⊝ ⊞ ⊟ ⊠
    ⁰ ¹ ² ³ ⁴ ⁵ ⁶ ⁷ ⁸ ⁹ ⁺ ⁻ ⁼ ⁽ ⁾ ⁱ ⁿ 
    ₀ ₁ ₂ ₃ ₄ ₅ ₆ ₇ ₈ ₉ ₊ ₋ ₌ ₍ ₎ ₐ ₑ ₒ ᵢ ᵣ ᵤ ᵥ ₓ ᵦ ᵧ ᵨ ᵩ ᵪ 
    ¼ ½ ¾ ⅓ ⅔ ⅕ ⅖ ⅗ ⅘ ⅙ ⅚ ⅛ ⅜ ⅝ ⅞
    ∀ ∁ ∃ ∄ ∅ ¬ ˜ ∧ ∨ ⊻ ⊼ ⊽ ∩ ∪ ∈ ∉ ∊ ∋ ∌ ∍ ∖ ⊂ ⊃ ⊄ ⊅ ⊆ ⊇ ⊈ ⊉ ⊊ ⊋ R ⋄ O ≃ ≄ ⊌ ⊍ ⊎ ⋐ ⋑ ⋒ ⋓ ⋀ ⋁ ⋂ ⋃ ⋎ ⋏ ⊕ ⊗ ⊖ ⊘ s ⋲ ⋳ ⋴ ⋵ ⋶ ⋷ ⋸ ⋹ ⋺ ⋻ ⋼ ⋽ ⋾ ⋿
    Α α Β β Γ γ Δ δ Ε ε Ζ ζ Η η Θ θ Ι ι Κ κ Λ λ Μ μ Ν ν Ξ ξ Ο ο Π π Ρ ρ Σ σ ς Τ τ Υ υ Φ φ Χ χ Ψ ψ Ω ω
));
my @colors = qw(black blue cyan green magenta red yellow white);

$_->meta->make_immutable(
    inline_constructor => 0,
    inline_accessors   => 1,
)
for qw(Player Place Place::Thing Place::Tile UI);

POE::Session->create
  ( inline_states =>
      { _start => \&_start,
        got_keystroke => \&keystroke_handler,
        help_keystroke => \&help_handler,
        chat_keystroke => \&chat_handler,
        player_move_rel => \&player_move_rel,
        add_player => \&add_player,
        player_chat => \&player_chat,
        new_map => \&new_map,
        remove_player => \&remove_player,
        connect_start => \&connect_start,
        connect_success => \&connect_success,
        connect_failure => \&connect_failure,
        server_input => \&server_input,
        server_error => \&server_error,
        assign_id => \&assign_id,
      }
  );

POE::Kernel->run();
exit;

sub _start {
    my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];

    binmode(STDOUT,':utf8');

    $heap->{console} = POE::Wheel::Curses->new(
        InputEvent => 'got_keystroke'
    );

    $heap->{ui} = UI->new();

    my ($username,$symbol) = $heap->{ui}->get_login_info();

    $heap->{ui}->debug("login info: $username $symbol");

    output("Building world, please wait...");
    $heap->{ui}->refresh();

    $heap->{place} = Place->new();

    $heap->{ui}->place($heap->{place});

    $heap->{ui}->setup();


    output("Welcome to CuteGirls!\nPress '?' for help.\n");
    $heap->{players} = { };
    $kernel->yield('connect_start');
}

sub connect_start {
    my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];

    $heap->{server} = POE::Wheel::SocketFactory->new(
           RemoteAddress  => '127.0.0.1',
           RemotePort     => 3456,
           SuccessEvent   => 'connect_success',
           FailureEvent   => 'connect_failure'
         );

}

sub assign_id {
    my ($heap, $id) = @_[HEAP, ARG0];
    $heap->{my_id} = $id;
    random_player($heap);
    #output("assigned id: $id\n");
    $heap->{ui}->refresh();
}

sub keystroke_handler {
    my ($kernel, $heap, $keystroke, $wheel_id) = @_[KERNEL, HEAP, ARG0, ARG1];

    #output("keypress: $keystroke\n");
     $heap->{ui}->refresh();
     given ($keystroke) {
         when [KEY_UP, 'k'] { send_to_server('player_move_rel',$heap->{my_id},0,-1) }
         when [KEY_DOWN, 'j'] { send_to_server('player_move_rel',$heap->{my_id},0,1) }
         when [KEY_LEFT, 'h'] { send_to_server('player_move_rel',$heap->{my_id},-1,0) }
         when [KEY_RIGHT, 'l'] { send_to_server('player_move_rel',$heap->{my_id},1,0) }
         when 'n' { send_to_server('remove_player',$heap->{my_id}); random_player($heap); };
         when "\r" {
             $heap->{console}->[2] = 'chat_keystroke';
             output_colored($heap->{players}->{$heap->{my_id}}->symbol,$heap->{players}->{$heap->{my_id}}->color,'input');
             $heap->{ui}->output(': ', 'input');
             $heap->{ui}->redraw();
             curs_set(1);
         }
         when 'r' { $heap->{ui}->redraw() }
         when '?' { $heap->{ui}->panels->{help}->top_panel(); $heap->{ui}->redraw(); $heap->{console}->[2] = 'help_keystroke'; }
         when 'q' { send_to_server('remove_player',$heap->{my_id}); delete $heap->{console}; delete $heap->{server_socket}  } # how to tell POE to kill the session?
     }
}

sub help_handler {
    my ($kernel, $heap, $keystroke, $wheel_id) = @_[KERNEL, HEAP, ARG0, ARG1];

    #output("help keypress: $keystroke\n");
     $heap->{ui}->refresh();
     given ($keystroke) {
         default { $heap->{ui}->panels->{help}->bottom_panel(); $heap->{ui}->redraw(); $heap->{console}->[2] = 'got_keystroke'; }
     }
}

sub chat_handler {
    my ($kernel, $heap, $keystroke, $wheel_id) = @_[KERNEL, HEAP, ARG0, ARG1];

    #output("help keypress: $keystroke\n");
     $heap->{ui}->refresh();
     given ($keystroke) {
         when 263 {
             my $msg = substr($heap->{chat_message},0,-1);
             $heap->{chat_message} = $msg;
             $heap->{ui}->panels->{input}->panel_window->echochar("\n");
             output_colored($heap->{players}->{$heap->{my_id}}->symbol,$heap->{players}->{$heap->{my_id}}->color,'input');
             $heap->{ui}->output(': ', 'input');
             $heap->{ui}->panels->{input}->panel_window->addstr($msg);
             $heap->{ui}->redraw() 
         }
         when "\r" { 
             send_to_server('player_chat',$heap->{my_id},$heap->{chat_message});
             $heap->{console}->[2] = 'got_keystroke';
             $heap->{chat_message} = '';
             $heap->{ui}->output("\n",'input');
             $heap->{ui}->redraw();
             curs_set(0);
         }
         default {
             $heap->{chat_message} .= $keystroke;
             $heap->{ui}->panels->{input}->panel_window->echochar($keystroke);
             $heap->{ui}->redraw() 
         }
     }
}

sub random_player {
    my $heap = shift;
    my $symbol = $sigils[int(rand $#sigils)];
    my $fg = $colors[1 + int(rand ($#colors - 1))];
    #my $bg = $colors[int(rand ($#colors - 1))];
    send_to_server('add_player',$heap->{my_id},$symbol,$fg,'black',5,5) 
}

sub send_to_server {
    my $socket = ${peek_my(1)->{'$heap'}}->{server_socket};
    $socket->put(\@_);
}

sub player_move_rel {
    my ($kernel, $heap, $player_id, $x, $y) = @_[KERNEL, HEAP, ARG0, ARG1, ARG2];
    $heap->{players}->{$player_id}->move_rel($x,$y);
    #output("Player $player_id moving $x,$y\n");
    $heap->{ui}->refresh();
}

sub add_player {
    my ($kernel, $heap, $id, $symbol, $fg, $bg, $y, $x) = @_[KERNEL, HEAP, ARG0, ARG1, ARG2, ARG3, ARG4, ARG5];
    my $player = Player->new(
                        symbol => $symbol,
                        color => $heap->{ui}->colors->{$fg}->{$bg},
                        tile => $heap->{place}->chart->[$y][$x],
                        id => $id,
                        );
    $heap->{players}->{$id} = $player;
    output("New player '$symbol' at $x,$y id $id\n");
    $heap->{ui}->refresh();
}

sub player_chat {
    my ($kernel, $heap, $id, $message) = @_[KERNEL, HEAP, ARG0, ARG1];
    my $from = $heap->{players}->{$id};
    output_colored($from->symbol,$from->color);
    output(": $message");
    $heap->{ui}->refresh();
}

sub new_map {
    my ($kernel, $heap, $map) = @_[KERNEL, HEAP, ARG0];

    #output("loading new map");

    $heap->{place}->load($map,$heap->{ui}->panels->{place},$heap->{ui});
    $heap->{place}->chart->[3][3]->enter(Place::Thing->new(color=>$heap->{ui}->colors->{'red'}->{'black'},symbol=>'%'));
    $heap->{ui}->refresh();
    $heap->{ui}->redraw();
    ungetch('r');
}

sub remove_player {
    my ($kernel, $heap, $id) = @_[KERNEL, HEAP, ARG0];
    unless ( defined($heap->{players}->{$id}) ) {
        output("Attempt to remove invalid player id $id\n");
        $heap->{ui}->refresh();
        return;
    }
    my $symbol = $heap->{players}->{$id}->symbol();
    output("Remove player '$symbol' id $id\n");
    $heap->{players}->{$id}->clear();
    delete $heap->{players}->{$id};
    $heap->{ui}->refresh();
}

sub connect_success {
    my ($kernel, $heap, $socket) = @_[KERNEL, HEAP, ARG0];

    $heap->{server_socket} = POE::Wheel::ReadWrite->new(
         'Handle'     => $socket,
         'Driver'     => POE::Driver::SysRW->new,
         'Filter'     => POE::Filter::Reference->new,
         'InputEvent' => 'server_input',
         'ErrorEvent' => 'server_error',
         'AutoFlush'  => 1,
    );

}

sub connect_failure {
    die "couldn't connect to server\n";
}

sub server_input {
    my ($kernel, $heap, $input) = @_[KERNEL, HEAP, ARG0];

    my ($cmd, @rest) = @$input;

    $kernel->yield($cmd, @rest);
}

sub server_error {
    die "problem with network stuff I guess\n";
}

sub output {
    my $message = shift;
    my $panel = shift;
    chomp $message;
    ${peek_my(1)->{'$heap'}}->{ui}->output("$message\n",$panel);
}

sub output_colored {
    my $message = shift;
    my $color = shift;
    my $panel = shift;
    ${peek_my(1)->{'$heap'}}->{ui}->output_colored($message,$color,$panel);
}
