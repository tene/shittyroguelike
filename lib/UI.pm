package UI;

use Curses qw(initscr keypad start_color noecho cbreak curs_set endwin new_panel update_panels doupdate init_pair COLOR_BLACK COLOR_BLUE COLOR_CYAN COLOR_GREEN COLOR_MAGENTA COLOR_RED COLOR_WHITE COLOR_YELLOW COLOR_PAIR $LINES $COLS);

use Moose;
use Perl6::Attributes;
use Perl6::Subs;

has place_panel => (is=>'rw',isa=>'Curses::Panel');
has output_panel => (is=>'rw',isa=>'Curses::Panel');
has place => (is=>'rw',isa=>'Place');
has win => (is=>'rw',isa=>'Curses::Window');
has colors => (is=>'rw',isa=>'HashRef[HashRef[Int]]');

method BUILD ($params) {

    my $win = new Curses();
    initscr();
    start_color();
    noecho();
    cbreak();
    curs_set(0);
    $win->keypad(1);

    my $pw = Curses->new($LINES-5,$COLS-30,0,0);
    $pw->scrollok(1);
    $pw->leaveok(1);
    my $dw = Curses->new(5,$COLS-30,$LINES-5,0);
    $dw->scrollok(1);
    $dw->leaveok(1);
    my $dp = new_panel($dw);
    my $pp = new_panel($pw);

    $.win = $win;
    $.place_panel = $pp;
    $.output_panel = $dp;
    
    my $c = {
        black => COLOR_BLACK,
        blue => COLOR_BLUE,
        cyan => COLOR_CYAN,
        green => COLOR_GREEN,
        magenta => COLOR_MAGENTA,
        red => COLOR_RED,
        white => COLOR_WHITE,
        yellow => COLOR_YELLOW,
    };

    my $cols = {};
    my $color_pair = 1;
    for my $i (keys %$c) {
        $cols->{$i} = {};
        for my $j (keys %$c) {
            init_pair($color_pair,$c->{$i},$c->{$j});
            $cols->{$i}->{$j} = COLOR_PAIR($color_pair);
            $color_pair++;
        }
    }

    $.colors = $cols;
}


method redraw {
    for my $line (@{$.place->chart}) {
        for my $tile (@$line) {
            $tile->draw();
        }
    }
    update_panels();
    refresh();
}

sub refresh {
    update_panels();
    doupdate();
}

sub setup {
    my ($self) = @_;
}

sub teardown {
    my ($self) = @_;
    curs_set(1);
    endwin();
    print "Thanks for playing!\n";
}

1;
