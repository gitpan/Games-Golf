# 00basic.t
#
# Basic test: try to load all modules at once.
#
# $Id: 00basic.t,v 1.6 2002/05/12 13:34:34 book Exp $

use strict;
use Test;

BEGIN { plan tests => 1 }

use Games::Golf;
use Games::Golf::Entry;
use Games::Golf::TestSuite;
use Games::Golf::OS;

my $loaded++;

END { ok($loaded) }
