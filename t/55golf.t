# 55golf.t
#
# Games::Golf tests.
#
# $Id: 55golf.t,v 1.2 2002/05/23 18:44:59 book Exp $

use strict;
use Test;

use Games::Golf;
use Games::Golf::TestSuite;

my ( $golf, $test );

# in most of those tests, we break encapsulation

$golf = Games::Golf->new( 't/tpr02.glf' );

$test = $golf->{testers}{anagrams};
ok( $test->get_id, 2 );

$golf = Games::Golf->new( 't/tpr03.glf' );
$test = $golf->{testers}{cantor};

# check we got a tiebreaker
my $tie1 = $test->get_tiebreaker;
ok( ref $tie1, 'CODE' );

# check that kola's tiebreaker was defined
# and is the same (default)
$test = $golf->{testers}{kola};
my $tie2 = $test->get_tiebreaker;
ok( "$tie1", "$tie2" );

BEGIN { plan tests => 3 }
