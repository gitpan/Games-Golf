# 41tcheck.t
#
# Games::Golf::TestSuite methods: check() and run()
#
# $Id: 41tcheck.t,v 1.5 2002/05/26 00:27:47 book Exp $

use strict;
use Test;

use Games::Golf::TestSuite;
use Games::Golf::Entry;
use t::Sweeties;

my  ($test, $entry, $result);

#----------------------------------------#
#          Test check method             #
#----------------------------------------#

$test = Games::Golf::TestSuite->new( $TESTSUITE{compile} );
$test->set_type( 'script' );
$test->set_name( 't/dummy.pl' );
$test->set_version( '12' );

# check that the file isn't changed by check()
$entry = Games::Golf::Entry->new( code => "# test" );

$test->check( $entry );
open F, 't/dummy.pl';
my $text = join '', <F>;
close F;

chomp $text; # as cross-platform as possible
ok( $text, '# dummy' );

# test the GGE version
ok( $entry->version, '12' );

#----------------------------------------#
#          Test run method               #
#----------------------------------------#

BEGIN { plan tests => 2 }
