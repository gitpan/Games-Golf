# 12win9xnl.t
#
# Low-level Games::Golf::TestSuite methods: _capture_win9x_nolimit()
#
# $Id: 12win9xnl.t,v 1.5 2002/05/13 16:44:00 book Exp $

use strict;
use Test;

use Games::Golf::TestSuite;
use Games::Golf::OS qw/ :functions /;

# a trick to save typing
*method = \&Games::Golf::TestSuite::_capture_win9x_nolimit;
my $self = bless {}, 'Games::Golf::TestSuite';
my $perl = qq{"$^X"};

my ( $out, $err, $code );
my $in = "abcd\n" x 20;

( $out, $err, $code ) = method( $self, $perl, q{-pe "1"}, \$in );
ok( $$out,  $in );
ok( $$err,  "" );
ok( $code, 0 );

# no need to pollute the output of make test
$in = "Windows 9x can't catch STDERR!\n";

( $out, $err, $code ) = method( $self, $perl, q{-e "print STDERR <>"}, \$in );
ok( $$out,  "" );
ok( $$err,  "" ); # this method cannot catch STDERR
ok( $code, 0 );

( $out, $err, $code ) = method( $self, $perl, q{-pe "print STDERR"}, \$in );
ok( $$out, $in );
ok( $$err, ""  ); # this method cannot catch STDERR
ok( $code, 0 );

( $out, $err, $code ) = method( $self, $perl, q{-e "exit 12"} );
ok( $$out,  "" );
ok( $$err,  "" );
ok( $code, 0 );   # Windows 9x doesn't set $? on exit

BEGIN {
    # this is Windows only
    if (is_Windows9x) { plan tests => 12 }
    else { plan tests => 0; exit }
}
