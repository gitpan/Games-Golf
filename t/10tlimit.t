# 10tlimit.t
#
# Games::Golf::TestSuite methods: limit()
# (This method is used by some of the low-level methods)
#
# $Id: 10tlimit.t,v 1.4 2002/05/22 18:57:50 book Exp $

use strict;
use Test;

use Games::Golf::TestSuite;
use t::Sweeties;

my $test;
my ( %limit, $temp );

#----------------------------------------#
#        Check the constructor           #
#----------------------------------------#

eval { Games::Golf::TestSuite->new( $TESTSUITE{broken} ) };
ok( $@, qr/^fatal: failed to compile testsuite:/ );

$test = Games::Golf::TestSuite->new( $TESTSUITE{compile} );
ok( ref $test, 'Games::Golf::TestSuite' );

#----------------------------------------#
#        Check the limit method          #
#----------------------------------------#

$test = Games::Golf::TestSuite->new( $TESTSUITE{compile} );
%limit = $test->limit;

# --- Check defaults ---

ok( defined $limit{time},   '' );
ok( defined $limit{stdout}, '' );
ok( defined $limit{stderr}, '' );
ok( defined $limit{opcode}, '' );

# --- Check get/set accessors ---

foreach my $attr ( "time", "stdout", "stderr" ) {

    # Attempt setting invalid data
    eval { $test->limit( $attr => "1char" ) };
    ok( $@, qr!Invalid limit! );

    # Set value
    $test->limit( $attr => 1 );

    # Read value
    $temp = $test->limit($attr);
    ok( $temp, 1 );

    # Set value to undef
    $test->limit( $attr => undef );

    # Read value
    $temp = $test->limit($attr);
    ok( defined $temp, '' );
}

# --- Check opcode get/set accessor ---
# NB: TODO: Currently should warn when
#     and attempt to set it is made.

# --- Check set w.r.t multiple values ---

# Set, previous returned
%limit = $test->limit(stdout => 1, stderr => 2);

ok(defined $limit{stdout}, '');
ok(defined $limit{stderr}, '');
ok(scalar keys %limit, 4);

# Set, previous returned
%limit = $test->limit(stdout => undef, stderr => undef);

ok( $limit{stdout}, 1 );
ok( $limit{stderr}, 2 );
ok( scalar keys %limit, 4 );

# Get, current values
%limit = $test->limit;

ok(defined $limit{stdout}, '');
ok(defined $limit{stderr}, '');
ok(scalar keys %limit, 4);

# --- Check fails on invalid data ---

# Bad value
eval { $test->limit(stdout => "1char") };
ok( $@, qr!Invalid limit value '1char' for stdout! );

# Odd number of elements
eval { $test->limit(stdout => 1, "shouldn\'t be here") };
ok( $@, qr!Key/value pairs required when setting limits! );

# --- Check context ---

# Scalar
$temp = scalar $test->limit(stdout => undef);
ok($temp, qr!^\d+/\d+$!); # Nobody should be doing this anyway

BEGIN { plan tests => 27 }
