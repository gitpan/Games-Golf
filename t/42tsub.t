# 42tsub.t
#
# Games::Golf::TestSuite methods: makesub(), sub(), and ok()
#
# $Id: 42tsub.t,v 1.3 2002/05/22 18:57:51 book Exp $

use strict;
use Test;

use Games::Golf::TestSuite;
use Games::Golf::Entry;
use t::Sweeties;

my  ($test, $entry, $result);

$entry = Games::Golf::Entry->new();

#----------------------------------------#
#          Test makesub method           #
#----------------------------------------#

$test = Games::Golf::TestSuite->new( $TESTSUITE{compile} );
$test->set_type( 'sub' );

# this is a valid subroutine
$entry->code( 'my $self = shift; return @_;' );
$result = $test->check( $entry );
ok( $result->[0], 1 );
ok( $result->[1], 1 );
ok( $result->[2], "" );

# Load sub with broken code
$entry->code( '/*/' );
$result = $test->check( $entry );
ok( $result->[0], 1 );
ok( $result->[1], 0 );
ok( $result->[2], qr/^Subroutine doesn't compile!/ );

#----------------------------------------#
#          Test sub method               #
#----------------------------------------#

#
# Are direct tests possible?
#

#
# tests through check()
#

$test = Games::Golf::TestSuite->new( $TESTSUITE{testsub}, 'sub.pl' );
$test->set_type( 'sub' );

# An okay sub
$entry->code( '++$_[0]' );
$result = $test->check( $entry );
ok( $result->[0], 3 );
ok( $result->[1], 3 );
ok( $result->[2], "" );
ok( $result->[3], "" );
ok( $result->[4], "" );

# An almost okay sub
$entry->code( '$_[0]++' );
$result = $test->check( $entry );
ok( $result->[0], 3 );
ok( $result->[1], 2 );
ok( $result->[2], "" );
ok( $result->[3], "" );
ok( $result->[4], "expected:\n--\n12--\ngot:\n--\n11--\n" );

# Load sub with broken code
$entry->code( '/*/' );
$result = $test->check( $entry );
ok( $result->[0], 1 );
ok( $result->[1], 0 );
ok( $result->[2], qr/^Subroutine doesn't compile!/ );

#----------------------------------------#
#          Test ok method                #
#----------------------------------------#

# TODO

BEGIN { plan tests => 19 }
