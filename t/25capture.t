# 25capture.t
#
# Games::Golf::TestSuite internal API methods: capture()
#
# $Id: 25capture.t,v 1.9 2002/05/25 09:30:40 book Exp $

use strict;
use Test;

use Games::Golf::TestSuite;
use Games::Golf::OS qw/ :windows /;

my $test;
my ($in, $out, $err, $exit);

# a trick to save typing
*method = \&Games::Golf::TestSuite::_capture_nolimit;
my $self = bless {}, 'Games::Golf::TestSuite';
my $perl = qq{"$^X"};

$in = << 'EOI';
some input
and some more
more more more
EOI

# Multi-implementations tests

# Basic usage
($out, $err, $exit) =
    method( $self, $perl, q!-pe "END{print STDERR 'stderr'}"!, \$in);
ok( $$out, $in );
ok( $$err, "stderr" ); # fails under Windows 9x
ok( $exit, 0 );

# nothing on STDIN
($out, $err, $exit) = method( $self, $perl, q!-e "print 'some output'"!);
ok( $$out, "some output" );
ok( $$err, "" );
ok( $exit, 0 );

# nothing on STDERR
($out, $err, $exit) = method( $self, $perl, q!-pe ""!, \$in);
ok( $$out, $in );
ok( $$err, "" );
ok( $exit, 0 );

# some exit code
($out, $err, $exit) = method( $self, $perl, q!-e "exit 123"!);
ok( $$out, "" );
ok( $$err, "" );
skip( is_Windows9x, $exit, 123 ); # fails under Windows 9x

BEGIN { plan tests => 12 }
