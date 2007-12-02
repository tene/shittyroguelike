package UI;

use Curses qw(initscr keypad start_color noecho cbreak curs_set endwin new_panel update_panels doupdate);

use Moose;

has place_panel => (is=>'rw',isa=>'Curses::Panel');
has output_panel => (is=>'rw',isa=>'Curses::Panel');
has place => (is=>'rw',isa=>'Place');
has player => (is=>'rw',isa=>'Player');
has win => (is=>'rw',isa=>'Curses::Window');

sub BUILD {
    my ($self, $params) = @_;

    my $win = new Curses();
    initscr();
    start_color();
    noecho();
    cbreak();
    curs_set(0);
    $win->keypad(1);

    my $pw = Curses->new(25,50,0,0);
    $pw->scrollok(1);
    $pw->leaveok(1);
    my $dw = Curses->new(5,50,25,0);
    $dw->scrollok(1);
    $dw->leaveok(1);
    my $dp = new_panel($dw);
    my $pp = new_panel($pw);

    $self->win($win);
    $self->place_panel($pp);
    $self->output_panel($dp);
}


sub redraw {
    my ($self) = @_;
    for my $line (@{$self->place->chart}) {
        for my $tile (@$line) {
            $tile->draw();
        }
    }
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
