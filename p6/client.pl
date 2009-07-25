use Curses:from<parrot>;
use UI;

my $ui = UI.new();
$ui.info(q{O HAI!
Welcome to the game!
There will be dancing and food and lulz.
});
my $dude = Actor.new(:y(5), :x(5), :symbol<@>);
$ui.draw($dude);
$ui.sync();
loop {
    my $ch = getch();
    given chr($ch) {
        when 'h' | chr(260) {
            $dude.x -= 1;
        }
        when 'j' | chr(258) {
            $dude.y += 1;
        }
        when 'k' | chr(259) {
            $dude.y -= 1;
        }
        when 'l' | chr(261) {
            $dude.x += 1;
        }
        when 'q' | chr(27) {
            last
        }
    }
    $ui.main.clear();
    $ui.draw($dude);
    $ui.info($ch ~ "({chr($ch)})");
    $ui.sync();
}
endwin();
