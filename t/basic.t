use Test;

BEGIN { plan tests => 1 }

use Games::Golf;
$loaded++;

END { ok($loaded) }
