# 52gcache.t
#
# Games::Golf methods: the cache dump() and load()
#
# $Id: 52gcache.t,v 1.2 2002/05/31 23:27:40 book Exp $

use strict;
use Test;

use Games::Golf;
use Games::Golf::Entry;
use POSIX qw/ tmpnam /;

my ( $golf, $entry, $cached );

$golf = Games::Golf->new('t/tpr02.glf');

$entry = Games::Golf::Entry->new(
    code  => '$A++;',
    hole  => 'anagrams',
    email => 'foo@bar.com',
);

my $file = tmpnam();
END { unlink $file; }

$golf->add($entry);
$golf->dump($file);

# is the file valid?
ok( 1, do $file );

# Check the content of the result file
my $entries = $Games::Golf::_entries;

ok( 1, scalar keys %{$entries} );

$cached = ( values %{$entries} )[0];    # there can only be one
ok( $cached->code,  $entry->code );
ok( $cached->hole,  $entry->hole );
ok( $cached->email, $entry->email );

# Now check what the GG object got back
$golf->load($file);

$cached = ( values %{ $golf->{entries} } )[0]; # encapsulation break
ok( $cached->code,  $entry->code );
ok( $cached->hole,  $entry->hole );
ok( $cached->email, $entry->email );

# TODO: test a multiple entry cache

BEGIN { plan tests => 8 }
