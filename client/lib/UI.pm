=head1 NAME

UI - Main class for user interface.

=cut

package UI;

use Term::ReadKey;
use Curses qw(initscr keypad start_color noecho cbreak curs_set endwin new_panel update_panels doupdate init_pair
    COLOR_BLACK COLOR_BLUE COLOR_CYAN COLOR_GREEN COLOR_MAGENTA COLOR_RED COLOR_WHITE COLOR_YELLOW COLOR_PAIR
    O_ACTIVE O_EDIT A_UNDERLINE
    $LINES $COLS
    newwin derwin subwin delwin resizeterm
    erase
    box
    top_panel bottom_panel hide_panel show_panel replace_panel
    new_field set_field_buffer field_opts_off set_field_back
    new_form set_form_win set_form_sub post_form unpost_form
    );
use sigtrap 'handler', \&handle_resize, 'WINCH';

use Moose;
use Perl6::Attributes;
use Perl6::Subs;

use Curses::Forms;

has panels => (is=>'rw',isa=>'HashRef[Curses::Panel]');
has place => (is=>'rw',isa=>'Place');
has win => (is=>'rw',isa=>'Curses::Window');
has colors => (is=>'rw',isa=>'HashRef[HashRef[Int]]');
has focus_x => (is=>'rw',isa=>'Int',default=>0);
has focus_y => (is=>'rw',isa=>'Int',default=>0);

my $ui;

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
    $sw->scrollok(0);
    $sw->leaveok(1);
    $sw->box(0,0);
    my $hw = Curses->new(5,50,10,15);
    $hw->scrollok(1);
    $hw->leaveok(1);
    $hw->addstr("\n               Press Enter to chat\n         Press 'd' to drop a new asterisk\n       ←↑↓→ and hjkl will move your player\n Press '?' to dismiss this window and 'q' to quit");
    $hw->box(0,0);
    my $dp = new_panel($dw);
    my $pp = new_panel($pw);
    my $fp = new_panel($fw);
    my $ip = new_panel($iw);
    my $sp = new_panel($sw);
    my $hp = new_panel($hw);
    $sp->hide_panel();
    $fp->hide_panel();
    $hp->hide_panel();

    $.win = $win;
    $.panels->{place} = $pp;
    $.panels->{output} = $dp;
    $.panels->{form} = $fp;
    $.panels->{input} = $ip;
    $.panels->{status} = $sp;
    $.panels->{help} = $hp;

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
    $ui = $self;
}

method DESTROY {
    $self->teardown();
}

sub handle_resize {
    my ($cols,$lines) = GetTerminalSize();
    resizeterm($lines,$cols);
    print STDERR "$lines $cols\n";
    sub helper ($p,$l,$c,$y,$x) {
        my $oldwin = $ui->panels->{$p}->panel_window;
        my $w = Curses->new($l,$c,$y,$x);
        $ui->panels->{$p}->replace_panel($w);
        delwin($oldwin);
        #$p->move_panel($y,$x);
    }
    helper('place',$lines-6,$cols-30,0,0);
    helper('output',5,$cols-30,$lines-5,0);
    #$fp->replace_panel($pw->wresize(0,0))->move_panel(0,0);
    helper('input',1,$cols-30,$lines-6,0);
    helper('status',0,30,0,$cols-30);
    #$hp->replace_panel($pw->wresize(5,50))->move_panel(10,15);
    $ui->redraw();
}

method output ($message,?$panel) {
    $panel ||= 'output';
    $self->panels->{$panel}->panel_window->addstr($message);
}

method output_colored ($message,$fg,$bg,?$panel) {
    $panel ||= 'output';
    my $color = $.colors->{$fg}->{$bg};
    $self->panels->{$panel}->panel_window->attron($color);
    $self->panels->{$panel}->panel_window->addstr($message);
    $self->panels->{$panel}->panel_window->attroff($color);
}

=head2 Methods

=over 4

=item C<redraw>

Redraws each tile in the map, then calls C<refresh()>.
Just calls C<drawtile()> on each tile in place->chart.

=cut


method redraw {
    $self->update_status();
    erase($.panels->{place}->panel_window);
    for my $line (@{$.place->chart}) {
        for my $tile (@$line) {
            $self->drawtile($tile);
        }
    }
    update_panels();
    refresh();
}

=item C<drawtile($tile)>

Draws the tile to the place panel.

=cut

method drawtile ($tile) {
    my $obj = $tile->contents->[-1] || $tile;
    my $y = $tile->y;
    my $x = $tile->x;
    $y -= $.focus_y;
    $x -= $.focus_x;
    $y += ($LINES-6)/2;
    $x += ($COLS-30)/2;
    return if $y < 0;
    return if $x < 0;
    my $color = $.colors->{$obj->fg}->{$obj->bg};
    $self->panels->{place}->panel_window->attron($color);
    $self->panels->{place}->panel_window->addstr($y,$x,$obj->symbol);
    $self->panels->{place}->panel_window->attroff($color);
}

=item C<update_status()>

Redraws the status panel.

=cut

method update_status {
    my $i = 1;
    my @players = sort {$a->username cmp $b->username} grep {(ref $_) eq 'Player'} values %{$self->place->objects};
    my @objects = sort {$a->id cmp $b->id} grep {(ref $_) ne 'Player'} values %{$self->place->objects};
    $self->panels->{status}->panel_window->erase();
    $self->panels->{status}->panel_window->box(0,0);
    for my $player (@players) {
        $self->panels->{status}->panel_window->addstr($i++,1,' 'x(9-((length $player->username)/2)) . "$player->{username}(");
        $self->output_colored($player->symbol,$player->fg,$player->bg,'status');
        $self->output(") $player->{cur_hp}/$player->{max_hp}",'status');
        $self->panels->{status}->panel_window->addstr($i++,1,' 'x(11-((length $player->username)/2)) . "Limbs: $player->{limbs}");
        $self->panels->{status}->panel_window->addstr($i++,1,' 'x(10-((length $player->username)/2)) . "Muscle: $player->{muscle}");
        $self->panels->{status}->panel_window->addstr($i++,1,' 'x(10-((length $player->username)/2)) . "Organs: $player->{organs}");
        $i++;
    }
    for my $obj (@objects) {
        $self->panels->{status}->panel_window->addstr($i++,1,' 'x9 . $obj->{id} .'(');
        $self->output_colored($obj->symbol,$obj->fg,$obj->bg,'status');
        $self->output(')','status');
    }
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

=item C<get_login_info()>

Displays a form to get a username.
Returns the username.

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
    LINES         => 6,
    CAPTION       => 'Login Info',
    CAPTIONCOL    => $cfg,
    BORDER        => 1,
    FOREGROUND    => $fg,
    BACKGROUND    => $bg,
    FOCUSED       => 'Username',
    TABORDER      => [qw(Username Buttons)],
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
      Buttons     => {
        TYPE      => 'ButtonSet',
        LABELS    => [@buttons],
        Y         => 3,
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
      );
}

=item C<get_new_player_info()>

Uses Displays a form to get information to create a new player.
Returns a list of [username, symbol].

=cut

sub get_new_player_info {
    my ($self,$message,$gods,$colors,$races) = @_;
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
    COLUMNS       => 38,
    LINES         => 13,
    CAPTION       => $message,
    CAPTIONCOL    => $cfg,
    BORDER        => 1,
    FOREGROUND    => $fg,
    BACKGROUND    => $bg,
    FOCUSED       => 'Color',
    TABORDER      => [qw(Color God Race Buttons)],
    WIDGETS       => {
      Color   => {
        TYPE      => 'ListBox',
        CAPTION   => 'Color',
        CAPTIONCOL=> $cfg,
        Y         => 0,
        X         => 0,
        FOREGROUND=> $fg,
        BACKGROUND=> $bg,
        COLUMNS   => 13,
        LINES     => 3,
        LISTITEMS => $colors,
        TOPELEMENT=> 0,
        VALUE     => 0,
        READONLY  => 1,
        FOCUSSWITCH => "\t\n\r",
        },
      God   => {
        TYPE      => 'ListBox',
        CAPTION   => 'God',
        CAPTIONCOL=> $cfg,
        Y         => 0,
        X         => 15,
        FOREGROUND=> $fg,
        BACKGROUND=> $bg,
        COLUMNS   => 21,
        LINES     => 3,
        LISTITEMS => $gods,
        TOPELEMENT=> 0,
        VALUE     => 0,
        READONLY  => 1,
        FOCUSSWITCH => "\t\n\r",
        },
      Race   => {
        TYPE      => 'ListBox',
        CAPTION   => 'Race',
        CAPTIONCOL=> $cfg,
        Y         => 5,
        X         => 0,
        FOREGROUND=> $fg,
        BACKGROUND=> $bg,
        COLUMNS   => 21,
        LINES     => 3,
        LISTITEMS => $races,
        TOPELEMENT=> 0,
        VALUE     => 0,
        READONLY  => 1,
        FOCUSSWITCH => "\t\n\r",
        },
      Buttons     => {
        TYPE      => 'ButtonSet',
        LABELS    => [@buttons],
        Y         => 10,
        X         => 10,
        BORDER    => 1,
        FOREGROUND=> $fg,
        BACKGROUND=> $bg,
        OnExit    => $btnexit,
        FOCUSSWITCH => "\t\n\r",
        },
      },
    });
    $form->execute($.panels->{form}->panel_window->subwin(0,0,2,10));

    $.panels->{form}->hide_panel();
    return (#$form->getWidget('Buttons')->getField('VALUE'),
      $form->getWidget('Race')->getField('VALUE'),
      $form->getWidget('God')->getField('VALUE'),
      $form->getWidget('Color')->getField('VALUE'),
    );
}

1;
