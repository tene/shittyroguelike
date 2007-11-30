package UI;

use Moose;
use Term::Screen;
use Term::ANSIColor;

has scr => (is=>'rw');
has place => (is=>'rw');
has player => (is=>'rw');

sub BUILD {
    my ($self, $params) = @_;
    $self->scr(new Term::Screen);
    unless ($self->scr) { die " Something's wrong \n"; }
}

sub clear_player {
    my ($self) = @_;
    my $color = $self->place->chart->[$self->player->y][$self->player->x]->color;
    print color $color if $color;
    $self->scr->at($self->player->y,$self->player->x)->puts($self->place->chart->[$self->player->y][$self->player->x]->symbol() || ' ');
    print color 'reset' if $color;
}

sub draw_player {
    my ($self) = @_;
    print color $self->player->color;
    $self->scr->at($self->player->y,$self->player->x)->bold()->puts($self->player->symbol)->normal();
    print color 'reset';
}

sub redraw {
    my ($self) = @_;
    my $i = 0;
    $self->scr->clrscr();
    for my $line (@{$self->place->chart}) {
        $self->scr->at($i++,0)->puts(join('',map {$_->symbol()} @$line));
    }
    $self->draw_player();
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
