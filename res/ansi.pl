#!/usr/bin/perl

use Term::ANSIColor;

my @mods = (
"",
"bold\t"      ,
"dark\t"      ,
"underline" ,
"blink\t"     ,
"reverse\t"   ,
"concealed" ,
);
            
my @colors = (
"black\t"     ,
"red\t"       ,
"green\t"     ,
"yellow\t"    ,
"blue\t"      ,
"magenta\t"   ,
"cyan\t"      ,
"white\t"     ,
);

for my $mod (@mods) {
    for my $color (@colors) {
        print color "$mod $color";
        my $print = $mod || $color;
        print "$print\t";
        print color 'reset';
    }
    print "\n";
}
