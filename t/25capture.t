# 25capture.t
#
# Games::Golf::TestSuite internal API methods: capture()
#
# $Id: 25capture.t,v 1.8 2002/05/13 16:56:49 book Exp $

use strict;
use Test;

use Games::Golf::TestSuite;
use Games::Golf::OS qw/ :windows /;

my $test;
my ($in, $out, $err, $exit);

# initialisation
$test  = Games::Golf::TestSuite->new( '', 'empty.pl' );

$in = << 'EOI';
some input
and some more
EOI

# Multi-implementations tests

# Basic usage
($out, $err, $exit) =
    $test->capture( qq!"$^X"!, q!-pe "END{print STDERR 'stderr'}"!, \$in);
ok( $$out, $in );
skip( is_Windows9x, $$err, "stderr" ); # fails under Windows 9x
ok( $exit, 0 );

# nothing on STDIN
($out, $err, $exit) =
    $test->capture( qq!"$^X"!, q!-e "print 'some output'"!);
ok( $$out, "some output" );
ok( $$err, "" );
ok( $exit, 0 );

# nothing on STDERR
($out, $err, $exit) =
    $test->capture( qq!"$^X"!, q!-pe ""!, \$in);
ok( $$out, $in );
ok( $$err, "" );
ok( $exit, 0 );

# some exit code
($out, $err, $exit) =
    $test->capture( qq!"$^X"!, q!-e "exit 123"!);
ok( $$out, "" );
ok( $$err, "" );
skip( is_Windows9x, $exit, 123 ); # fails under Windows 9x

BEGIN { plan tests => 12 }
