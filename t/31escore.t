# 31escore.t
#
# Games::Golf::Entry methods: score()
#
# $Id: 31escore.t,v 1.1 2002/04/15 23:20:10 book Exp $

use strict;
use Test;
use Games::Golf::Entry;

my $entry;

# create a Games::Golf::Entry object
$entry = new Games::Golf::Entry(
    code   => qq(#!/usr/bin/perl -p0\ns/\n//g;warn y///c."\n"),
);

# compute score
ok( $entry->score, 25 );

# more tests needed!

BEGIN { plan tests => 1 }
