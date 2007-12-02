package UI;

use Moose;
use Term::Screen;
use Term::ANSIColor;

has scr => (is=>'rw',isa=>'Term::Screen');
has place => (is=>'rw');
has player => (is=>'rw');

sub BUILD {
    my ($self, $params) = @_;
    $self->scr(new Term::Screen);
    unless ($self->scr) { die " Something's wrong \n"; }
}


sub redraw {
    my ($self) = @_;
    my $i = 0;
    $self->scr->clrscr();
    for my $line (@{$self->place->chart}) {
        my $j = 0;
        for my $tile (@$line) {
            $tile->draw();
        }
        $i++;
    }
    #$self->player->draw();
}



sub setup {
    my ($self) = @_;
    $self->scr->clrscr();
    $self->scr->noecho();
    print $self->scr->term->Tputs('vi',1);
}

sub teardown {
    my ($self) = @_;
    $self->scr->clrscr();
    print $self->scr->term->Tputs('ve',1);
    print "Thanks for playing!\n";
}

1;
