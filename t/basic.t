use Test;

BEGIN { plan tests => 1 }

use Games::Golf;
use Games::Golf::Entry;
use Games::Golf::TestSuite;

$loaded++;

END { ok($loaded) }
