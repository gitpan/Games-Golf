# -*- cperl -*-
#

use strict;
use Test;

use Games::Golf::TestSuite;
use Games::Golf::Entry;

# try with a non-existing test suite
eval { my $test = Games::Golf::TestSuite->new( "t/null" ) };
ok( $@, qr!Can't open t/null: ! );

# now the file exists, but has compilation errors
eval { my $test = Games::Golf::TestSuite->new( "t/hole0" ) };
ok( $@, qr!Can't compile t/hole0: ! );

# this one should work
my $test = Games::Golf::TestSuite->new( "t/hole1" );
ok( ref $test, 'Games::Golf::TestSuite' );

# create a new entry
my $entry  = Games::Golf::Entry->new;

# broken code
$entry->code( << 'EOC' );
#!/usr/bin/perl
/*/; # ?+*{} follows nothing in regexp
EOC

my $result = $test->check( $entry );
ok( $result->[0], 1 );
ok( $result->[1], 0 );
ok( $result->[2], qr/ follows nothing / );

# was the entry modified too?
ok( $entry->result, $result );

# working code
$entry->code( << 'EOC' );
#!/usr/bin/perl
print "Hello, world!\n";
EOC

$result = $test->check( $entry );
ok( $result->[0], 1 );
ok( $result->[1], 1 );
ok( $result->[2], "" );

# now test some subs
$test = Games::Golf::TestSuite->new( "t/hole2" );

# doesn't compile
$entry->code( '/*/' );
$result = $test->check( $entry );
ok( $result->[0], 4 );
ok( $result->[1], 2 );
ok( $result->[2], qr/ follows nothing / );
ok( $result->[3], "expected:\n--\n11--\ngot:\n--\n10--\n" );

# does what's expected
$entry->code( '$_[0]++' );
$result = $test->check( $entry );
ok( $result->[0], 4 );
ok( $result->[1], 4 );
ok( $result->[2], "" );
ok( $result->[3], "" );
ok( $result->[4], "" );
ok( $result->[5], "" );

# test the code checkers
$test = Games::Golf::TestSuite->new( "t/hole3" );
$entry->code( << 'EOC' );
#!/usr/bin/perl -l0p
y/\n//;fork||die y///c.'
'
EOC

$result = $test->check( $entry );
ok( $result->[0], 5 );
ok( $result->[1], 3 );
ok( $result->[2], "" );
ok( $result->[3], "Oops, you embedded a '\n' in your code.\n" );
ok( $result->[4], "" );
ok( $result->[5], "Oops, your code matched (?-xism:y(.).*\\1.*\\1).\n" );
ok( $result->[6], "" );

#----------------------------------------#
#          Test the ioee stuff.          #
#----------------------------------------#

##-> Normal tests.
$test = Games::Golf::TestSuite->new( "t/hole4" );
# $test->ioee( << 'EOI', << 'EOO', "" );
# foo
# bar
# baz
# EOI
# foo
# bar
# baz
# EOO

# all is ok.
$entry->code( << 'EOC' );
#!/usr/bin/perl
print while (<>);
EOC

$result = $test->check( $entry );
ok( $result->[0], 2 );
ok( $result->[1], 2 );
ok( $result->[2], "" );
ok( $result->[3], "" );

# wrong output.
$entry->code( << 'EOC' );
#!/usr/bin/perl
print uc while (<>);
EOC

$result = $test->check( $entry );
ok( $result->[0], 2 );
ok( $result->[1], 1 );
ok( $result->[2], "" );
ok( $result->[3], qr!\AOops, wrong output! );

# wrong stderr.
$entry->code( << 'EOC' );
#!/usr/bin/perl
print while (<>);
END{ warn "End reached.\n" }
EOC

$result = $test->check( $entry );
ok( $result->[0], 2 );
ok( $result->[1], 1 );
ok( $result->[2], "" );
ok( $result->[3], qr!\AOops, wrong stderr! );

##-> Check undef values.
$test = Games::Golf::TestSuite->new( "t/hole5" );
# $test->ioee( "blah", undef, undef, undef );

$entry->code( << 'EOC' );
#!/usr/bin/perl
print while (<>);
END{ warn "End reached.\n" }
EOC

# Don't care about anything...
$result = $test->check( $entry );
ok( $result->[0], 1 );
ok( $result->[1], 1 );
ok( $result->[2], "" );

##-> Check exit code.
$test = Games::Golf::TestSuite->new( "t/hole6" );
# $test->ioee( "blah", undef, undef, 17 );

# Right exit code.
$entry->code( << 'EOC' );
#!/usr/bin/perl
exit 17
EOC

$result = $test->check( $entry );
ok( $result->[0], 1 );
ok( $result->[1], 1 );
ok( $result->[2], "" );

# Wrong exit code.
$entry->code( << 'EOC' );
#!/usr/bin/perl
exit 16
EOC

$result = $test->check( $entry );
ok( $result->[0], 1 );
ok( $result->[1], 0 );
ok( $result->[2], qr!\AOops, wrong exit code.! );

##-> Check time-out.
$test = Games::Golf::TestSuite->new( "t/hole7" );
# $test->ioee( "blah", "blah", undef, undef, time => 2 );

# Sleep forever.
$entry->code( << 'EOC' );
#!/usr/bin/perl
sleep;
EOC

$result = $test->check( $entry );
skip( $^O eq 'MSWin32', $result->[0], 1 );
skip( $^O eq 'MSWin32', $result->[1], 0 );
skip( $^O eq 'MSWin32', $result->[2], "Oops, timed out while running script." );

BEGIN { plan tests => 51 }
