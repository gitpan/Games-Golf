# 32eok.t
#
# Games::Golf::Entry methods: ok()
#
# $Id: 32eok.t,v 1.1 2002/04/15 23:20:12 book Exp $

use strict;
use Test;
use Games::Golf::Entry;

my $entry;

# create a Games::Golf::Entry object
$entry = new Games::Golf::Entry();

# let's test the ok() function
$entry->result( [ 0, 0 ] );
$entry->ok( 1, "boubouge" );
$entry->ok( 0, "mourienche" );
$entry->ok( 0 );
$entry->ok( 1 );
ok( $entry->result->[0], 4 );
ok( $entry->result->[1], 2 );
ok( $entry->result->[2], "" );
ok( $entry->result->[3], "mourienche" );
ok( $entry->result->[4], "Test failed with no message." );
ok( $entry->result->[5], "" );

BEGIN { plan tests => 6 }
