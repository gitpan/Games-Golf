# 42tsub.t
#
# Games::Golf::TestSuite methods: aioee() and loop()
#
# $Id: 42taioee.t,v 1.6 2002/05/22 18:57:51 book Exp $

use strict;
use Test;

use Games::Golf::TestSuite;
use Games::Golf::Entry;
use Games::Golf::OS qw/ :windows /;
use t::Sweeties;

my ( $test, $entry, $result );

$entry = Games::Golf::Entry->new();

#
# All the skip()ed tests are due to the poor cpabilities
# of Windows9x regarding the capture of STDERR and the exit code.
# 

#----------------------------------------#
#          Test aioee method             #
#----------------------------------------#

#
# Simple aioee() tests
#

$test = Games::Golf::TestSuite->new( $TESTSUITE{aioee1} );
$test->set_type( 'script' );
$test->set_name( 'aioee.pl' );

# --- Should work ---

$entry->code( << 'EOC' );
#!/usr/bin/perl
print while (<>);
EOC

$result = $test->check($entry);

ok( $result->[0], 2 );
ok( $result->[1], 2 );
ok( $result->[2], "" );
ok( $result->[3], "" );

# --- Shouldn't work (wrong STDOUT) ---

$entry->code( << 'EOC' );
#!/usr/bin/perl
print uc while (<>);
EOC

$result = $test->check($entry);

ok( $result->[0], 2 );
ok( $result->[1], 1 );
ok( $result->[2], "" );
ok( $result->[3], qr!\AWrong output on stdout! );

# --- Shouldn't work (wrong STDERR) ---

$entry->code( << 'EOC' );
#!/usr/bin/perl
print while (<>);
END{ warn "End reached.\n" }
EOC

$result = $test->check($entry);

ok( $result->[0], 2 );
skip( is_Windows9x, $result->[1], 1 );
ok( $result->[2], "" );
skip( is_Windows9x, $result->[3], qr!\AWrong output on stderr! );

# --- Should work (we don't care about exit code, ---
# --- since it's "" or undef in the Sweetie)      ---

$entry->code( << 'EOC' );
#!/usr/bin/perl
print while (<>);
exit 123;
EOC

$result = $test->check($entry);

ok( $result->[0], 2 );
ok( $result->[1], 2 );
ok( $result->[2], "" );
ok( $result->[3], "" );

#
# Check exit code.
#
$test = Games::Golf::TestSuite->new( $TESTSUITE{aioee2} );
$test->set_type( 'script' );
$test->set_name( 'aioee.pl' );

# Correct exit code.
$entry->code('exit 17;');

$result = $test->check($entry);
ok( $result->[0], 2 );
skip( is_Windows9x, $result->[1], 2 );
ok( $result->[2], "" );
skip( is_Windows9x, $result->[3], "" );

# Wrong exit code.
$entry->code('exit 16;');

$result = $test->check($entry);
ok( $result->[0], 2 );
skip( is_Windows9x, $result->[1], 1 );
ok( $result->[2], "" );
skip( is_Windows9x, $result->[3], qr!\AWrong exit code! );

#
# Check the exceptions returned by aioee
#

# Too many parameters exception
$test = Games::Golf::TestSuite->new( $TESTSUITE{aioeeX1} );
$test->set_type( 'script' );
$test->set_name( 'aioee.pl' );

eval { $result = $test->check($entry); };
ok( $@, qr/^Too many parameters passed/ );

# No output, errput, exit code exception
$test = Games::Golf::TestSuite->new( $TESTSUITE{aioeeX2} );
$test->set_type( 'script' );
$test->set_name( 'aioee.pl' );

eval { $result = $test->check($entry); };
ok( $@, qr/^At least one type of output must be checked/ );

$test = Games::Golf::TestSuite->new( $TESTSUITE{aioeeX3} );
$test->set_type( 'script' );
$test->set_name( 'aioee.pl' );

eval { $result = $test->check($entry); };
ok( $@, qr/^At least one type of output must be checked/ );

# Unrealistic exit code exception
$test = Games::Golf::TestSuite->new( $TESTSUITE{aioeeX4} );
$test->set_type( 'script' );
$test->set_name( 'aioee.pl' );

eval { $result = $test->check($entry); };
ok( $@, qr/^Integer between 0 and 255 required when checking exit code/ );

$test = Games::Golf::TestSuite->new( $TESTSUITE{aioeeX5} );
$test->set_type( 'script' );
$test->set_name( 'aioee.pl' );

eval { $result = $test->check($entry); };
ok( $@, qr/^Integer between 0 and 255 required when checking exit code/ );

#
# Tests of the Hint system
#

# none yet

#----------------------------------------#
#          Test loop method              #
#----------------------------------------#

$test = Games::Golf::TestSuite->new( $TESTSUITE{loop} );
$test->set_type( 'script' );
$test->set_name( 'loop.pl' );

$entry->code( << 'EOC' );
#!perl -p
s/fim/boom/
EOC
$result = $test->check($entry);
ok( $result->[0], 3 );
ok( $result->[1], 2 );
ok( $result->[2], "" );
ok( $result->[3], "" );
ok( $result->[4], qr!\AWrong output on stdout! );

BEGIN { plan tests => 34 }
