# 42tcompile.t
#
# Games::Golf::TestSuite methods: compile()
#
# $Id: 42tcompile.t,v 1.5 2002/05/22 18:57:51 book Exp $

use strict;
use Test;

use Games::Golf::TestSuite;
use Games::Golf::Entry;
use t::Sweeties;

my ( $test, $entry, $result );

$entry = Games::Golf::Entry->new();

#----------------------------------------#
#          Test compile method           #
#----------------------------------------#

$test = Games::Golf::TestSuite->new( $TESTSUITE{compile} );
$test->set_type( 'script' );
$test->set_name( 'test.pl' );

# --- Should compile ---

$entry->code( << 'EOC' );
#!/usr/bin/perl
print "Hello, world!\n";
EOC

$result = $test->check($entry);

ok( $result->[0], 1 );
ok( $result->[1], 1 );
ok( $result->[2], "" );

# Was the entry modified too?
ok( $result, $entry->result() );

# --- Won't compile ---

$entry->code( << 'EOC' );
#!/usr/bin/perl
/*/; # ?+*{} follows nothing in regexp
EOC

$result = $test->check($entry);
ok( $result->[0], 1 );
ok( $result->[1], 0 );
ok( $result->[2], qr/^Script doesn't compile!/ );

BEGIN { plan tests => 7 }
