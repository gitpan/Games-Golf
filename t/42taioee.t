# 42tsub.t
#
# Games::Golf::TestSuite methods: aioee()
#
# $Id: 42taioee.t,v 1.4 2002/05/13 16:53:55 book Exp $

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

$test = Games::Golf::TestSuite->new( $TESTSUITE{aioee1}, 'aioee.pl' );

# --- Should work ---

$entry->code( << 'EOC' );
#!/usr/bin/perl
print while (<>);
EOC

$result = $test->check($entry);

ok( $result->[0], 1 );
ok( $result->[1], 1 );
ok( $result->[2], "" );

# --- Shouldn't work (wrong STDOUT) ---

$entry->code( << 'EOC' );
#!/usr/bin/perl
print uc while (<>);
EOC

$result = $test->check($entry);

ok( $result->[0], 1 );
ok( $result->[1], 0 );
ok( $result->[2], qr!\AWrong output on stdout! );

# --- Shouldn't work (wrong STDERR) ---

$entry->code( << 'EOC' );
#!/usr/bin/perl
print while (<>);
END{ warn "End reached.\n" }
EOC

$result = $test->check($entry);

ok( $result->[0], 1 );
skip( is_Windows9x, $result->[1], 0 );
skip( is_Windows9x, $result->[2], qr!\AWrong output on stderr! );

# --- Should work (we don't care about exit code, ---
# --- since it's "" or undef in the Sweetie)      ---

$entry->code( << 'EOC' );
#!/usr/bin/perl
print while (<>);
exit 123;
EOC

$result = $test->check($entry);

ok( $result->[0], 1 );
ok( $result->[1], 1 );
ok( $result->[2], "" );

#
# Check exit code.
#
$test = Games::Golf::TestSuite->new( $TESTSUITE{aioee2}, 'aioee.pl' );

# Correct exit code.
$entry->code('exit 17;');

$result = $test->check($entry);
ok( $result->[0], 1 );
skip( is_Windows9x, $result->[1], 1 );
skip( is_Windows9x, $result->[2], "" );

# Wrong exit code.
$entry->code('exit 16;');

$result = $test->check($entry);
ok( $result->[0], 1 );
skip( is_Windows9x, $result->[1], 0 );
skip( is_Windows9x, $result->[2], qr!\AWrong exit code! );

#
# Check the exceptions returned by aioee
#

# Too many parameters exception
$test = Games::Golf::TestSuite->new( $TESTSUITE{aioeeX1}, 'aioee.pl' );

eval { $result = $test->check($entry); };
ok( $@, qr/^Too many parameters passed/ );

# No output, errput, exit code exception
$test = Games::Golf::TestSuite->new( $TESTSUITE{aioeeX2}, 'aioee.pl' );

eval { $result = $test->check($entry); };
ok( $@, qr/^At least one type of output must be checked/ );

$test = Games::Golf::TestSuite->new( $TESTSUITE{aioeeX3}, 'aioee.pl' );

eval { $result = $test->check($entry); };
ok( $@, qr/^At least one type of output must be checked/ );

# Unrealistic exit code exception
$test = Games::Golf::TestSuite->new( $TESTSUITE{aioeeX4}, 'aioee.pl' );

eval { $result = $test->check($entry); };
ok( $@, qr/^Integer between 0 and 255 required when checking exit code/ );

$test = Games::Golf::TestSuite->new( $TESTSUITE{aioeeX5}, 'aioee.pl' );

eval { $result = $test->check($entry); };
ok( $@, qr/^Integer between 0 and 255 required when checking exit code/ );

#
# Tests of the Hint system
#

# none yet

BEGIN { plan tests => 23 }
