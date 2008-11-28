package Curses::Widgets::ChooseWithText;

=head1 Curses::Widgets::ChooseWithText

This widget shows a pick list, using Curses::Widgets::ListBox, but
as the user moves between items, text is shown in a secondary
window.  All conf elements that don't start with "DATA" are just
like their ListBox counterparts.

Example:

         use Curses::Widgets::ListBox;

         $lb = Curses::Widgets::ListBox->new({
           CAPTION     => 'List',
           CAPTIONCOL  => 'yellow',
           COLUMNS     => 10,
           LINES       => 3,
           VALUE       => 0,
           INPUTFUNC   => \&scankey,
           FOREGROUND  => 'white',
           BACKGROUND  => 'black',
           SELECTEDCOL => 'green',
           BORDER      => 1,
           BORDERCOL   => 'red',
           FOCUSSWITCH => "\t",
           X           => 1,
           Y           => 1,
           TOPELEMENT  => 0,
           LISTITEMS   => [@list],

           DATAITEMS => [@list2],
           DATACOLUMNS   => 5,
           DATALINES     => 5,
           DATACAPTION => "dat",
           DATACAPTIONCOL => "red",
           DATAFOREGROUND => "white",
           DATABACKGROUND => "blue",
           DATABORDER => 1,
           DATABORDERCOL => "green",
          });

         $lb->draw($mwh, 1);

DATAITEMS gives a list of text to show in the data window when the
(numerically) corresponding item in LISTITEMS is under the user's
cursor.  The other DATA* configuration items work as their TextMemo
counterparts, as that's how it's generated internally.

=cut

use strict;
use vars qw($VERSION @ISA);
use Curses;
use Curses::Widgets;
use Curses::Widgets::ListBox;

($VERSION) = (q$Revision: 0.3 $ =~ /(\d+(?:\.(\d+))+)/);
@ISA = qw(Curses::Widgets::ListBox);

=head2 C<_conf>

Straight out of the tutorial

=cut

sub _conf {
    my $self = shift;
    my %conf = ( @_);
    my $err = 0;

    # Validate and initialise the widget's state
    # and store in the %conf hash

    # Always include the following
    $err = 1 unless $self->SUPER::_conf(%conf);

    return ($err == 0) ? 1 : 0;
}

=head2 C<_conf>

Straight out of the tutorial

=cut

sub _cursor {
    my $self = shift;
    $self->SUPER::_cursor(@_);
}

=head2 C<draw>

This in the only sub in which anything interesting happens; we
generate a Curses::Widgets::TextMemo using the DATA* configuration
items, and put the text in there.

=cut
sub draw {

    my $self = shift;
    my $mwh = shift;
    my $conf = $self->{CONF};

    use Curses::Widgets::TextMemo;

    my $lbl = Curses::Widgets::TextMemo->new({
	    COLUMNS     => $conf->{'DATACOLUMNS'},
	    LINES       => $conf->{'DATALINES'},
	    VALUE       => $conf->{'DATAITEMS'}->[$conf->{'CURSORPOS'}],
	    FOREGROUND  => $conf->{'DATAFOREGROUND'},
	    BACKGROUND  => $conf->{'DATABACKGROUND'},
	    BORDER	=> $conf->{'DATABORDER'},
	    BORDERCOL	=> $conf->{'DATABORDERCOL'},
	    CAPTION	=> $conf->{'DATACAPTION'},
	    CAPTIONCOL	=> $conf->{'DATACAPTIONCOL'},
	    X           => $conf->{'X'} + $conf->{'COLUMNS'} + ($conf->{'BORDER'} ? 2 : 0),
	    Y           => $conf->{'Y'},
	    READONLY	=> 1,
	    });

    $lbl->draw($mwh);

    $self->SUPER::draw($mwh, @_);
}

=head2 C<_conf>

Straight out of the tutorial

=cut

sub _content {
    my $self = shift;
    my $dwh = shift;
    my $conf = $self->{CONF};

    $self->SUPER::_content($dwh, @_);
}

=head2 C<_conf>

Straight out of the tutorial

=cut

sub input_key {
    my $self = shift;

    $self->SUPER::input_key(@_);

    # validate/update state information
}

1;
