package UI;

use Curses qw(initscr keypad start_color noecho cbreak curs_set endwin new_panel update_panels doupdate init_pair
    COLOR_BLACK COLOR_BLUE COLOR_CYAN COLOR_GREEN COLOR_MAGENTA COLOR_RED COLOR_WHITE COLOR_YELLOW COLOR_PAIR
    O_ACTIVE O_EDIT A_UNDERLINE
    $LINES $COLS
    newwin derwin
    box
    top_panel bottom_panel
    new_field set_field_buffer field_opts_off set_field_back
    new_form set_form_win set_form_sub post_form unpost_form
    );

use Moose;
use Perl6::Attributes;
use Perl6::Subs;

has place_panel => (is=>'rw',isa=>'Curses::Panel');
has output_panel => (is=>'rw',isa=>'Curses::Panel');
has form_panel => (is=>'rw',isa=>'Curses::Panel');
has help_panel => (is=>'rw',isa=>'Curses::Panel');
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
    my $fw = Curses->new(0,30,0,$COLS-30);
    $fw->scrollok(1);
    $fw->leaveok(1);
    $fw->box(0,0);
    my $hw = Curses->new(5,50,10,15);
    $hw->scrollok(1);
    $hw->leaveok(1);
    $hw->addstr("\n        Press 'n' to make a new character\n       ←↑↓→ and hjkl will move your player\n Press '/' to dismiss this window and 'q' to quit");
    $hw->box(0,0);
    my $dp = new_panel($dw);
    my $pp = new_panel($pw);
    my $fp = new_panel($fw);
    my $hp = new_panel($hw);

    $.win = $win;
    $.place_panel = $pp;
    $.output_panel = $dp;
    $.form_panel = $fp;
    $.help_panel = $hp;

    my @fl = make_login_fields();
    my $form = makeForm(@fl);
    $form->set_form_win($fw);
    $form->set_form_sub($fw);

    $form->post_form();
    refresh();
    
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

sub make_login_fields() {

    my $flist = [
                 [ 'L', 0,  0,  0,  2, "Form"        ],
                 [ 'L', 0,  0,  2,  0, "Name"  ],
                 [ 'F', 1, 15,  2, 12, "Name"      ],
                 [ 'L', 0,  0,  3,  0, "Symbol"   ],
                 [ 'F', 1, 15,  3, 12, "Symbol"      ],
                 ];

    my @fl;

    foreach my $F (@$flist) {
        my $field;
            # This is a Perl reference to a scalar number variable.  The
            # number is the numerical equivalent (cast) of the C pointer to the
            # executable-Curses FIELD object.  The reference is blessed into
            # package "Curses::Field", but don't confuse it with a Perl
            # object.

        if ($F->[0] eq 'L') {
            $field = new_field(1, length($F->[5]), $F->[3], $F->[4], 0, 0);
            if ($field eq '') {
                #fatal("new_field $F->[5] failed");
            }
            set_field_buffer($field, 0, $F->[5]);
            field_opts_off($field, O_ACTIVE);
            field_opts_off($field, O_EDIT);
        } elsif ($F->[0] eq 'F') {
            $field = new_field($F->[1], $F->[2], $F->[3], $F->[4], 0, 0);
            if ($field eq '') {
                #fatal("new_field $F->[5] failed");
            }
            set_field_back($field, A_UNDERLINE);
        }

        push(@fl, $field);
    }
    return @fl;
}

sub makeForm(@) {
    
    my @fl = @_;

    my @pack;
    foreach my $fieldR (@fl) {
        push(@pack, $ {$fieldR});
    }
    push(@pack, 0);

    # new_form()'s argument is a list of fields.  Its form is amazingly
    # complex:

    # The argument is a string whose ASCII encoding is an array of C
    # pointers.  Each pointer is to a FIELD object of the
    # executable-Curses library, except the last is NULL to mark the
    # end of the list.  For example, assume there are two fields and
    # the executable-Curses library represents them with FIELD objects
    # whose addresses (pointers) are 0x11223344 and 0x0004080C.  The
    # argument to Curses::new_form() is a 12 character string whose
    # ASCII encoding is 0x112233440004080C00000000 .

    # Maybe some day we can provide an alternative where there is an
    # actual Perl field object class and the argument is a reference to
    # a Perl list of them.

    my $form = new_form(pack('L!*', @pack));
    if ($form eq '') {
        fatal("new_form failed");
    }
    return $form;
}

1;
