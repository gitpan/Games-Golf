# 31etiebreak.t
#
# Games::Golf::Entry methods: tiebreak()
#
# $Id: 31etiebreak.t,v 1.1 2002/04/15 23:20:11 book Exp $

use strict;
use Test;
use Games::Golf::Entry;

my $entry;
my %temp;

# create a Games::Golf::Entry object
$entry = new Games::Golf::Entry();

#-----------------------------------------#
#          Tie-breaking scorers.          #
#-----------------------------------------#

# Weird-chars: only regular text.
$entry->code( qq(some code that does not compile) );
ok( $entry->tiebreak("weird"), 1 );

# Weird-chars: only garbage.
$entry = new Games::Golf::Entry(
    code => qq($%@/!\:-+*{}[]&#"'|^=.;,)
);
ok( $entry->tiebreak("weird"), 0 );

# Cache mechanism.
$entry->code( qq(some code that does not compile) );
ok( $entry->tiebreak("weird"), 0 );

# pass your own sub
ok( $entry->tiebreak( sub { 13 } ), 13 );

# ask for several tiebreakers
%temp = $entry->tiebreak( 'date', sub { }, 'weird' );
ok( exists $temp{date},        1 );
ok( exists $temp{weird},       1 );
ok( exists $temp{userdefined}, 1 );

%temp = $entry->tiebreak;
ok( keys %temp != 0 );

BEGIN { plan tests => 8 }
