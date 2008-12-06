package ManualExpect;

sub fake { bless {} };

sub expect { print "Manual Expect Expecting @_.\n"; };

sub send { print "Manual Expect Sending @_.\n"; };

1;
