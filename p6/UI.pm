use Curses:from<parrot>;

class Drawable {
    has $.x is rw;
    has $.y is rw;
    has $.symbol is rw;
}

class Dacti is Drawable {
    has $.tile is rw;
    method leave {
        $!tile.?remove(self);
        my $tmp = $!tile;
        $!tile = Failure;
        return $tmp;
    }
}

class Actor is Dacti {
}

class Tile is Drawable {
    has $.contents;

    method symbol {
        if defined($!contents) {
            return $!contents.symbol;
        }
        else {
            return $!symbol;
        }
    }
    method remove(Dacti $obj) {
        $!contents = Failure;
        return $obj;
    }
    method insert(Dacti $obj) {
        $!contents = $obj;
        $obj.tile = self;
    }
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
    method draw($d) {
        mvwaddstr($.win, $d.y, $d.x, $d.symbol);
    }
}

class UI {
    has $!stdscr;
    has $.main;
    has $!status;
    has $!info;
    has $!x;
    has $!y;
    has $!tiles;
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
        my $fh = open '../server/maps/map1.txt';
        my $tiles = $fh.lines>>.split('');
        my $tilelist = gather for $tiles.kv -> $y, @t {
            take [ gather for @t.kv -> $x, $floor {
                $main.addstr($y, $x, $floor);
                my $tile = Tile.new(:y($y), :x($x), :symbol($floor));
                take $tile;
            }];
        };
        self.bless(*, :x($x), :y($y), :main($main), :status($status), :info($info), :tiles($tilelist));
    }
    method info($msg) {
        $!info.addstr("$msg\n");
    }
    multi method draw(Drawable $obj) {
        $!main.draw($obj);
    }
    multi method draw(Failure $fail) {
        $.info('Something asked to draw a fail...');
    }
    method clear(Drawable $obj) {
        $!main.addstr($obj.y, $obj.x, $!tiles[$obj.y][$obj.x].symbol);
    }
    method insert(Dacti $obj) {
        $!tiles[$obj.y][$obj.x].?insert($obj);
        $.draw($obj);
    }
    method sync {
        update_panels();
        doupdate();
        refresh();
    }
}

# vim: expandtab shiftwidth=4 ft=perl6:
