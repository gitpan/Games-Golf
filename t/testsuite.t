use strict;
use Test;

use Games::Golf::TestSuite;
use Games::Golf::Entry;

# try with a non-existing test suite
eval { my $test = Games::Golf::TestSuite->new( "t/null" ) };
ok( $@, qr!Can't open t/null: ! );

# now the file exists, but has compilation errors
eval { my $test = Games::Golf::TestSuite->new( "t/hole0" ) };
ok( $@, qr!Can't compile t/hole0: ! );

# this one should work
my $test = Games::Golf::TestSuite->new( "t/hole1" );
ok( ref $test, 'Games::Golf::TestSuite' );

# create a new entry
my $entry  = Games::Golf::Entry->new;

# broken code
$entry->code( << 'EOC' );
#!/usr/bin/perl
/*/; # ?+*{} follows nothing in regexp
EOC

my $result = $test->check( $entry );
ok( $result->[0], 1 );
ok( $result->[1], 0 );
ok( $result->[2], qr/ follows nothing in regexp/ );

# was the entry modified too?
ok( $entry->result, $result );

# working code
$entry->code( << 'EOC' );
#!/usr/bin/perl
print "Hello, world!\n";
EOC

$result = $test->check( $entry );
ok( $result->[0], 1 );
ok( $result->[1], 1 );
ok( $result->[2], "" );

# now test some subs
$test = Games::Golf::TestSuite->new( "t/hole2" );

# doesn't compile
$entry->code( '/*/' );
$result = $test->check( $entry );
ok( $result->[0], 4 );
ok( $result->[1], 2 );
ok( $result->[2], qr/ follows nothing in regexp/ );
ok( $result->[3], "expected:\n--\n11--\ngot:\n--\n10--\n" );

# does what's expected
$entry->code( '$_[0]++' );
$result = $test->check( $entry );
ok( $result->[0], 4 );
ok( $result->[1], 4 );
ok( $result->[2], "" );
ok( $result->[3], "" );
ok( $result->[4], "" );
ok( $result->[5], "" );

# test the code checkers
$test = Games::Golf::TestSuite->new( "t/hole3" );
$entry->code( << 'EOC' );
#!/usr/bin/perl -l0p
y/\n//;fork||die y///c.'
'
EOC

$result = $test->check( $entry );
ok( $result->[0], 5 );
ok( $result->[1], 3 );
ok( $result->[2], "" );
ok( $result->[3], "Oops, you embedded a '\n' in your code.\n" );
ok( $result->[4], "" );
ok( $result->[5], "Oops, your code matched (?-xism:y(.).*\\1.*\\1).\n" );
ok( $result->[6], "" );

BEGIN { plan tests => 27 }
