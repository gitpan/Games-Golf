#-*-perl-*-
#
# Test suite for Games::Golf::Entry
#

# Modules we rely on.
use Test;
use Games::Golf::Entry;

use strict;

my $entry;
my %temp;

# create a Games::Golf::Entry object
$entry = new Games::Golf::Entry(
    author => "foo",
    email  => 'foo@bar.com',
    nick   => "fubar",
    date   => "2002.02.01.12.34.59",
    hole   => "gs.pl",
    code   => qq(#!/usr/bin/perl -p0\ns/\n//g;warn y///c."\n"),
);

# check it was created
ok( ref $entry, "Games::Golf::Entry" );

# check the accessors don't exist yet
# (use subs prevents from using can)
# ok( ref $entry->can('nick'), '' );

# use an accessor and autoload the method
ok( $entry->nick, 'fubar' );

# check the method exists now
ok( ref $entry->can('nick'), 'CODE' );

# set the value to something else
$entry->nick( 'foobar' );
ok( $entry->nick, 'foobar' );

# try a non-existing accessor
eval { $entry->scoore; };
ok( $@, qr/Undefined method Games::Golf::Entry::scoore/ );

# compute score
ok( $entry->score, 25 );

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

BEGIN { plan tests => 20 };

