# 12winntnl.t
#
# Low-level Games::Golf::TestSuite methods: _capture_winnt_nolimit()
#
# $Id: 12winntnl.t,v 1.6 2002/05/13 16:29:27 book Exp $
#
# In case you didn't check, this file is almost identical to 12unixnl.t

use strict;
use Test;

use Games::Golf::TestSuite;
use Games::Golf::OS qw/ :functions /;

# a trick to save typing
*method = \&Games::Golf::TestSuite::_capture_winnt_nolimit;
my $self = bless {}, 'Games::Golf::TestSuite';
my $perl = qq{"$^X"};

my ( $out, $err, $code );
my $in = "abcd\n" x 20;

( $out, $err, $code ) = method( $self, $perl, q{-pe "1"}, \$in );
ok( $$out,  $in );
ok( $$err,  "" );
ok( $code, 0 );

( $out, $err, $code ) = method( $self, $perl, q{-e "print STDERR <>"}, \$in );
ok( $$out,  "" );
ok( $$err,  $in );
ok( $code, 0 );

( $out, $err, $code ) = method( $self, $perl, q{-pe "print STDERR"}, \$in );
ok( $$out,  $in );
ok( $$err,  $in );
ok( $code, 0 );

( $out, $err, $code ) = method( $self, $perl, q{-e "exit 12"} );
ok( $$out,  "" );
ok( $$err,  "" );
ok( $code, 12 );

BEGIN {
    # this is Windows only
    if (is_WindowsNT) { plan tests => 12 }
    else { plan tests => 0; exit }
}
