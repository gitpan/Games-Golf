# 12unixnl.t
#
# Low-level Games::Golf::TestSuite methods: _capture_unix_nolimit()
#
# $Id: 12unixnl.t,v 1.5 2002/05/12 19:57:51 book Exp $

use strict;
use Test;

use Games::Golf::TestSuite;
use Games::Golf::OS qw/ :functions /;

# a trick to save typing
*method = \&Games::Golf::TestSuite::_capture_unix_nolimit;
my $self = bless {}, 'Games::Golf::TestSuite';

my ( $out, $err, $code );
my $in = "abcd\n" x 20;

( $out, $err, $code ) = method( $self, $^X, q{-pe "1"}, \$in );
ok( $$out,  $in );
ok( $$err,  "" );
ok( $code, 0 );

( $out, $err, $code ) = method( $self, $^X, q{-e "print STDERR <>"}, \$in );
ok( $$out,  "" );
ok( $$err,  $in );
ok( $code, 0 );

( $out, $err, $code ) = method( $self, $^X, q{-pe "print STDERR"}, \$in );
ok( $$out,  $in );
ok( $$err,  $in );
ok( $code, 0 );

( $out, $err, $code ) = method( $self, $^X, q{-e "exit 12"} );
ok( $$out,  "" );
ok( $$err,  "" );
ok( $code, 12 );

BEGIN {

    # this is Unix only
    if (is_Unix) { plan tests => 12 }
    else { plan tests => 0; exit }
}
