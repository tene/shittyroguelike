use Curses:from<parrot>;

role Drawable {
    has $.x is rw;
    has $.y is rw;
    has $.symbol is rw;
}

class Panel {
    has $.panel;
    method new($cols, $rows, $y, $x) {
        my $win = newwin($cols, $rows, $y, $x);
        leaveok($win,1);
        my $p = new_panel($win);
        self.bless(*, :panel($p));
    }
    method win { panel_window($!panel) }
    multi method addstr($y, $x, $msg) {
        mvwaddstr($.win, $y, $x, $msg);
    }
    multi method addstr($msg) {
        waddstr($.win, $msg);
    }
    method outline($verch, $horch) {
        box($.win, $verch, $horch);
    }
    method scroll($s) {
        scrollok($.win,$s);
    }
    method clear {
        werase($.win);
    }
    method draw(Drawable $d) {
        $.addstr($d.y, $d.x, $d.symbol);
    }
}

class Actor does Drawable {
}

class UI {
    has $!stdscr;
    has $.main;
    has $!status;
    has $!info;
    has $!x;
    has $!y;
    multi method new {
        my $std = initscr();
        noecho();
        cbreak();
        curs_set(0);
        keypad($std, 1);
        my $x = getmaxx($std);
        my $y = getmaxy($std);
        my $main = Panel.new($y-6, $x-15, 0, 0);
        my $status = Panel.new($y-6, 15, 0, $x-15);
        my $info = Panel.new(5, $x, $y-5, 0);
        $status.outline(0,0);
        $info.scroll(1);
        mvaddstr($y-6,0,'-'x$x);
        self.bless(*, :x($x), :y($y), :main($main), :status($status), :info($info));
    }
    method info($msg) {
        $!info.addstr("$msg\n");
    }
    method draw(Drawable $obj) {
        $!main.draw($obj);
    }
    method sync {
        update_panels();
        doupdate();
        refresh();
    }
}

