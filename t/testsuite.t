# -*- cperl -*-
#

use strict;
use Test;

use Games::Golf::TestSuite;
use Games::Golf::Entry;

my ( $entry, $result, $test );
my ( $temp,  @temp,   %temp );

#----------------------------------------#
#        Check the constructor           #
#----------------------------------------#

# Try loading a non-existant test suite.
eval { Games::Golf::TestSuite->new( "t/null" ) };
ok( $@, qr!Can't open testsuite file 't/null': ! );

# Try loading a broken test suite (does not compile).
eval { Games::Golf::TestSuite->new( "t/hole0" ) };
ok( $@, qr!Can't compile t/hole0: ! );

# Try loading a valid test suite.
eval { $test = Games::Golf::TestSuite->new( "t/hole1" ) };
ok( ref $test, 'Games::Golf::TestSuite' );
ok( $@, "" );

# Load standard test suite "t/hole1".
eval { $test = Games::Golf::TestSuite->new( "t/hole1" ) };
ok( ref $test, 'Games::Golf::TestSuite' );
ok( $@, "" );

# Create standard entry object.
eval { $entry = Games::Golf::Entry->new() };
ok( ref $entry, 'Games::Golf::Entry' );
ok( $@, "" );

#----------------------------------------#
#        Basic tests of new/check        #
#----------------------------------------#

# Load test suite "t/hole1"
$test = Games::Golf::TestSuite->new( "t/hole1" );
ok( ref $test, 'Games::Golf::TestSuite' );

# Load entry with broken code
$entry->code( << 'EOC' );
#!/usr/bin/perl
/*/; # ?+*{} follows nothing in regexp
EOC

# Check entry doesn't compile...
$result = $test->check( $entry );
ok( $result->[0], 1 );
ok( $result->[1], 0 );
ok( $result->[2], "Script doesn't compile!" );

# Was the entry modified too?
ok( $result, $entry->result() );

# Load entry with working code
$entry->code( << 'EOC' );
#!/usr/bin/perl
print "Hello, world!\n";
EOC

# Check entry works correctly
$result = $test->check( $entry );
ok( $result->[0], 1 );
ok( $result->[1], 1 );
ok( $result->[2], "" );

#----------------------------------------#
#   Basic tests of new/check with subs   #
#----------------------------------------#

# Load test suite "t/hole2";
$test = Games::Golf::TestSuite->new( "t/hole2" );
ok( ref $test, 'Games::Golf::TestSuite' );

# Load entry with broken code
$entry->code( '/*/' );

# Check entry doesn't pass the tests...
$result = $test->check( $entry );
ok( $result->[0], 4 );
ok( $result->[1], 2 );
ok( $result->[2], qr/ follows nothing / );
ok( $result->[3], "expected:\n--\n11--\ngot:\n--\n10--\n" );

# Load entry with working code
$entry->code( '$_[0]++' );

# Check entry does pass the tests...
$result = $test->check( $entry );
ok( $result->[0], 4 );
ok( $result->[1], 4 );
ok( $result->[2], "" );
ok( $result->[3], "" );
ok( $result->[4], "" );
ok( $result->[5], "" );

#----------------------------------------#
#     Test the code checking methods     #
#----------------------------------------#

# Load test suite "t/hole3";
$test = Games::Golf::TestSuite->new( "t/hole3" );
ok( ref $test, 'Games::Golf::TestSuite' );

# Load entry with working code
$entry->code( << 'EOC' );
#!/usr/bin/perl -l0p
y/\n//;fork||die y///c.'
'
EOC

# Test the code
$result = $test->check( $entry );

# Check entry does the right thing against the hole tests
ok( $result->[0], 5 );
ok( $result->[1], 3 );
ok( $result->[2], "" );
ok( $result->[3], "Oops, you embedded a '\n' in your code.\n" );
ok( $result->[4], "" );
ok( $result->[5], "Oops, your code matched (?-xism:y(.).*\\1.*\\1).\n" );
ok( $result->[6], "" );

#----------------------------------------#
#      Test the limit accessor           #
#----------------------------------------#


# Check defaults are correct
%temp = $test->limit();
ok( $temp{time},   undef );
ok( $temp{stdout}, undef );
ok( $temp{stderr}, undef );
ok( $temp{opcode}, undef );

# Check get/set accessors
foreach my $attr ("time", "stdout", "stderr") {

    # Set to value 1, using void context
    $test->limit($attr => 1);

    # Attempt setting invalid data
    eval { $test->limit($attr => "1char") };
    ok( $@, qr!Invalid limit! );

    # Read value
    $temp = $test->limit($attr);
    ok( $temp, 1 );

    # Set to undef, using void context
    $test->limit($attr => undef);

    # Read value
    $temp = $test->limit($attr);
    ok( $temp, undef );
}

# Check behaviour of limit w.r.t. multiple values
# they should have been reset to undef by at this point.
%temp = $test->limit(stdout => 1, stderr => 2);
ok( $temp{stdout}, undef );
ok( $temp{stderr}, undef );
ok( scalar keys %temp, 4 );

%temp = $test->limit(stdout => undef, stderr => undef);
ok( $temp{stdout}, 1 );
ok( $temp{stderr}, 2 );
ok( scalar keys %temp, 4 );

# Check it properly fails on invalid data.
eval { $test->limit(stdout => "1char") };
ok( $@, qr!Invalid limit value '1char' for stdout! );

# Check odd number of elements fails.
eval { $test->limit(stdout => 1, "shouldn\'t be here") };
ok( $@, qr!Key/value pairs required when setting limits! );

# Check scalar context
$temp = scalar $test->limit(stdout => undef);
ok( $temp, qr!^\d+/\d+$! ); # Nobody should be doing this anyway

# TODO: Tests for opcode... currently should just throw a warning

#----------------------------------------#
#          Test the aioee stuff.         #
#----------------------------------------#

# Load test suite "t/hole4";
$test = Games::Golf::TestSuite->new( "t/hole4" );
ok( ref $test, 'Games::Golf::TestSuite' );

# $test->aioee( "", << 'EOI', << 'EOO', "" );
# foo
# bar
# baz
# EOI
# foo
# bar
# baz
# EOO

# Load entry with working code
$entry->code( << 'EOC' );
#!/usr/bin/perl
print while (<>);
EOC

# Check entry does pass the tests...
$result = $test->check( $entry );
ok( $result->[0], 2 );
ok( $result->[1], 2 );
ok( $result->[2], "" );
ok( $result->[3], "" );

# Load entry with incorrect code (wrong STDOUT)
$entry->code( << 'EOC' );
#!/usr/bin/perl
print uc while (<>);
EOC

# Check entry doesn't pass the tests...
$result = $test->check( $entry );
ok( $result->[0], 2 );
ok( $result->[1], 1 );
ok( $result->[2], "" );
ok( $result->[3], qr!\AOops, wrong output! );

# Load entry with incorrect code (wrong STDOUT)
$entry->code( << 'EOC' );
#!/usr/bin/perl
print while (<>);
END{ warn "End reached.\n" }
EOC

# Check entry doesn't pass the tests...
$result = $test->check( $entry );
ok( $result->[0], 2 );
ok( $result->[1], 1 );
ok( $result->[2], "" );
ok( $result->[3], qr!\AOops, wrong stderr! );

# Check undef values.
$test = Games::Golf::TestSuite->new( "t/hole5" );
# $test->aioee( "", "blah", undef, undef, undef );

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

# Check exit code.
$test = Games::Golf::TestSuite->new( "t/hole6" );
# $test->aioee( "", "blah", undef, undef, 17 );

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

#----------------------------------------#
#        Check the limit enforcement     #
#----------------------------------------#

# Check time-out.
#$test = Games::Golf::TestSuite->new( "t/hole7" );
# $test->aioee( "", "blah", "blah", undef, undef, time => 2 );

# Sleep forever.
#$entry->code( << 'EOC' );
##!/usr/bin/perl
#sleep;
#EOC

#$result = $test->check( $entry );
#skip( $^O eq 'MSWin32', $result->[0], 1 );
#skip( $^O eq 'MSWin32', $result->[1], 0 );
#skip( $^O eq 'MSWin32', $result->[2],
#      "Oops, timed out (2 seconds) while running script." );


# we need tests for the a of aioee!


BEGIN { plan tests => 79 }
