# 40taccess.t
#
# Games::Golf::TestSuite methods: new() and accessors.
#
# $Id: 40taccess.t,v 1.7 2002/05/23 17:16:00 book Exp $

use strict;
use Test;

use Games::Golf::TestSuite;
use Games::Golf::OS qw/ :functions /;
use t::Sweeties;    # import the %TESTSUITE hash

my $test = Games::Golf::TestSuite->new( $TESTSUITE{compile}, 'compile.pl' );

#----------------------------------------#
#        Check the accessors             #
#----------------------------------------#

# limit and new are tested in 10tlimit.t

# read arch
my $arch = $test->arch;

skip( !is_Unix      && 'not Unix',       $arch, qr/unix/ );
skip( !is_WindowsNT && 'not Windows NT', $arch, qr/winnt/ );
skip( !is_Windows9x && 'not Windows 9x', $arch, qr/win9x/ );

# set to a non-existing architecture
my $old = $test->arch( 'foobar' );

ok( $old, $arch );       # arch() returned the previous one
ok( $old, $test->arch ); # and didn't change anything

# set to an existing architecture
$old = $test->arch( 'unix' );
ok( $old, $arch );         # arch() returned the previous one
ok( $test->arch, 'unix' ); # and set the new one

# the autoloaded accessors
for my $key ( qw/ id version type name tiebreaker / ) {
    my $method = "set_$key";
    my $val = int rand 100;
    $test->$method( $val );
    ok( $test->$method(), $val );
}

BEGIN { plan tests => 12 }

