#-*- cperl -*-

use strict;
use Test;

use Games::Golf::TestSuite;
use Games::Golf::Entry;
use t::Sweeties;

my ( $entry, $result, $test );
my ( $temp,  @temp,   %temp );

$entry = Games::Golf::Entry->new();

#----------------------------------------#
#        Check the limit enforcement     #
#----------------------------------------#

# we have to check that it can enforce limits

#----------------------------------------#
#        Test the run method             #
#----------------------------------------#

BEGIN { plan tests => 0 };

__END__

#----------------------------------------#
#     Test the code checking methods     #
#----------------------------------------#

# Load test suite "t/hole3";
$test = Games::Golf::TestSuite->new( "t/hole3" );
ok( ref $test, 'Games::Golf::TestSuite' );

# Load entry with working code
$entry->code( << 'EOC' );
#!/usr/bin/perl -l0p
y/\n//;fork||die y///c.'
'
EOC

# Test the code
$result = $test->check( $entry );

# Check entry does the right thing against the hole tests
ok( $result->[0], 5 );
ok( $result->[1], 3 );
ok( $result->[2], "" );
ok( $result->[3], "Oops, you embedded a '\n' in your code.\n" );
ok( $result->[4], "" );
ok( $result->[5], "Oops, your code matched (?-xism:y(.).*\\1.*\\1).\n" );
ok( $result->[6], "" );

#----------------------------------------#
#        Check the limit enforcement     #
#----------------------------------------#


# Check time-out.
#$test = Games::Golf::TestSuite->new( "t/hole7" );
# $test->aioee( "", "blah", "blah", undef, undef, time => 2 );

# Sleep forever.
#$entry->code( << 'EOC' );
##!/usr/bin/perl
#sleep;
#EOC

#$result = $test->check( $entry );
#skip( $^O eq 'MSWin32', $result->[0], 1 );
#skip( $^O eq 'MSWin32', $result->[1], 0 );
#skip( $^O eq 'MSWin32', $result->[2],
#      "Oops, timed out (2 seconds) while running script." );


# we need tests for the a of aioee!

#----------------------------------------#
#        Test the run method             #
#----------------------------------------#
$test = Games::Golf::TestSuite->new( "t/hole6" );
# $test->aioee( "", "blah", undef, undef, 17 );
@temp = ();

# this one should not even compile
push @temp, Games::Golf::Entry->new( code => "/*/" );

# this one doesn't pass the only test
push @temp, Games::Golf::Entry->new( code => << 'EOC' );
#!/usr/bin/perl
exit 17
EOC

# this entry should not be tested anyway
$temp[0]->result( [ 4, 3 ] );

$test->run( @temp );
ok( $temp[0]->result->[0], 4 );
ok( $temp[0]->result->[1], 3 );
ok( $temp[1]->result->[0], 1 );
ok( $temp[1]->result->[1], 1 );

BEGIN { plan tests => 78 }
