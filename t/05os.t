# 05os.t
#
# Basic test: the Games::Golf::OS helper module
#
# $Id: 05os.t,v 1.2 2002/05/13 16:54:50 book Exp $

use strict;
use Test;

use Games::Golf::OS qw/ :functions os_name /;

# we can't test much, but at least this:
if ( $^O eq 'MSWin32' ) {
    ok( is_Windows(), qr/^(?:9x|NT)$/ );
    ok( is_Unix(),    "" );
}

# this will break under a non-Unix, non-Windows system
else {
    ok( is_Windows(), "" );
    ok( is_Unix(),    $^O );
}

ok( defined( os_name() ), 1 );

BEGIN { plan tests => 3 }
