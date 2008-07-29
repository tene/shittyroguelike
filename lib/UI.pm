=head1 NAME

UI - Main class for user interface.

=cut

package UI;

use Curses qw(initscr keypad start_color noecho cbreak curs_set endwin new_panel update_panels doupdate init_pair
    COLOR_BLACK COLOR_BLUE COLOR_CYAN COLOR_GREEN COLOR_MAGENTA COLOR_RED COLOR_WHITE COLOR_YELLOW COLOR_PAIR
    O_ACTIVE O_EDIT A_UNDERLINE
    $LINES $COLS
    newwin derwin subwin delwin
    box
    top_panel bottom_panel hide_panel show_panel
    new_field set_field_buffer field_opts_off set_field_back
    new_form set_form_win set_form_sub post_form unpost_form
    );

use Moose;
use Perl6::Attributes;
use Perl6::Subs;

use Curses::Forms;

has panels => (is=>'rw',isa=>'HashRef[Curses::Panel]');
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

    my $pw = Curses->new($LINES-6,$COLS-30,0,0);
    $pw->scrollok(1);
    $pw->leaveok(1);
    my $dw = Curses->new(5,$COLS-30,$LINES-5,0);
    $dw->scrollok(1);
    $dw->leaveok(1);
    my $fw = Curses->new(0,0,0,0);
    $fw->scrollok(1);
    $fw->leaveok(1);
    $fw->box(0,0);
    my $iw = Curses->new(1,$COLS-30,$LINES-6,0);
    $iw->scrollok(1);
    $iw->leaveok(1);
    my $sw = Curses->new(0,30,0,$COLS-30);
    $sw->scrollok(1);
    $sw->leaveok(1);
    my $hw = Curses->new(6,50,10,15);
    $hw->scrollok(1);
    $hw->leaveok(1);
    $hw->addstr("\n               Press Enter to chat\n        Press 'n' to make a new character\n       ←↑↓→ and hjkl will move your player\n Press '?' to dismiss this window and 'q' to quit");
    $hw->box(0,0);
    my $dp = new_panel($dw);
    my $pp = new_panel($pw);
    my $fp = new_panel($fw);
    my $ip = new_panel($iw);
    my $sp = new_panel($sw);
    my $hp = new_panel($hw);
    $fp->hide_panel();
    $hp->hide_panel();

    $.win = $win;
    $.panels->{place} = $pp;
    $.panels->{output} = $dp;
    $.panels->{form} = $fp;
    $.panels->{input} = $ip;
    $.panels->{status} = $sp;
    $.panels->{help} = $hp;

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

method DESTROY {
    $self->teardown();
}

method output ($message,?$panel) {
    $panel ||= 'output';
    $self->panels->{$panel}->panel_window->addstr($message);
}

method output_colored ($message,$color,?$panel) {
    $panel ||= 'output';
    $self->panels->{$panel}->panel_window->attron($color);
    $self->panels->{$panel}->panel_window->addstr($message);
    $self->panels->{$panel}->panel_window->attroff($color);
}

=head2 Methods

=over 4

=item C<redraw>

Redraws each tile in the map, then calls C<refresh()>.

=cut


method redraw {
    for my $line (@{$.place->chart}) {
        for my $tile (@$line) {
            $tile->draw();
        }
    }
    update_panels();
    refresh();
}

=item C<refresh()>

Calls Curses' "redraw everything" functions.

=cut

sub refresh {
    update_panels();
    doupdate();
}

sub setup {
    my ($self) = @_;
}

=item C<debug()>

Writes a string to the output panel.

=cut

sub debug {
    my ($self, $message) = @_;
    $self->panels->{output}->panel_window->addstr("» $message\n");
}

=item C<teardown()>

Restores the cursor, closes down Curses, prints an exit message.

=cut

sub teardown {
    my ($self) = @_;
    curs_set(1);
    endwin();
    print "Thanks for playing!\n";
}

# Internal function
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

=item C<get_login_info()>

Uses Displays a form to get a username and a player symbol.
Returns a list of [username, symbol].

=cut

sub get_login_info {
    my ($self) = @_;
    $.panels->{form}->show_panel();
    my ($fg,$bg,$cfg) = qw(white black yellow);
    my @buttons = qw(OK);

    my $btnexit = sub {
        my ($f,$key) = @_;

        return unless ($key eq "\r" || $key eq "\n");
        $f->setField(EXIT => 1);
    };

    my   $form = Curses::Forms->new({
    AUTOCENTER    => 1,
    DERIVED       => 1,
    COLUMNS       => 23,
    LINES         => 9,
    CAPTION       => 'Login Info',
    CAPTIONCOL    => $cfg,
    BORDER        => 1,
    FOREGROUND    => $fg,
    BACKGROUND    => $bg,
    FOCUSED       => 'Username',
    TABORDER      => [qw(Username Symbol Buttons)],
    WIDGETS       => {
      Username   => {
        TYPE      => 'TextField',
        CAPTION   => 'Username',
        CAPTIONCOL=> $cfg,
        Y         => 0,
        X         => 0,
        FOREGROUND=> $fg,
        BACKGROUND=> $bg,
        COLUMNS   => 21,
        MAXLENGTH => 32,
        FOCUSSWITCH => "\t\n\r",
        },
      Symbol   => {
        TYPE      => 'TextField',
        CAPTION   => 'Symbol',
        CAPTIONCOL=> $cfg,
        Y         => 3,
        X         => 0,
        FOREGROUND=> $fg,
        BACKGROUND=> $bg,
        COLUMNS   => 21,
        MAXLENGTH => 1,
        FOCUSSWITCH => "\t\n\r",
        },
      Buttons     => {
        TYPE      => 'ButtonSet',
        LABELS    => [@buttons],
        Y         => 6,
        X         => 5,
        BORDER    => 1,
        FOREGROUND=> $fg,
        BACKGROUND=> $bg,
        OnExit    => $btnexit,
        FOCUSSWITCH => "\t\n\r",
        },
      },
    });
    $form->execute($.panels->{form}->panel_window->subwin(0,0,($LINES/2)-5,($COLS/2)-12));

    $.panels->{form}->hide_panel();
    return (#$form->getWidget('Buttons')->getField('VALUE'),
      $form->getWidget('Username')->getField('VALUE'),
      $form->getWidget('Symbol')->getField('VALUE'));
}

1;
