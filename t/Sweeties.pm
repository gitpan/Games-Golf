package t::Sweeties;

# This package only has one variable, that holds various testsuite
# programs that are use to test Games::Golf::TestSuite and other
# bits that use Games::Golf::TestSuite.

# The %TESTCODE hash is used in various test files in t/

require Exporter;
@ISA    = qw/ Exporter /;
@EXPORT = qw/ %TESTSUITE /;

use vars qw/ %TESTSUITE /;

%TESTSUITE = (
    # a test with a compilation error
    broken => << '        EOT',
        /*/; # (5.6.0) ?+*{} follows nothing in regexp
             # (5.6.1) Quantifier follows nothing before
             #         HERE mark in regex m/* << HERE /
        EOT
    # a mini testsuite to test Games::Golf::TestSuite
    compile => '$A++;',
    testsub => << '        EOT',

        # test that $A is modified when $_[0] is modified in the sub
        $A = 10;
        $test->sub( $A );
        $test->ok( $A, 11 );

        $test->ok( $test->sub( $A ), 12 );
        EOT
    # 
    hole3 => << '        EOT',
        $test->not_string( "\n" );            # not ok
        $test->not_string( "warn" );          # ok
        $test->not_match( qr/y(.).*\1.*\1/ ); # not ok
        $test->not_match( 'warn' );           # ok
        EOT
    # test aioee with input and output
    aioee1 => '$test->aioee( "", "foo\nbar\nbaz\n", "foo\nbar\nbaz\n", "" );',
    # test aoiee with error code 17
    aioee2 => '$test->aioee( "", "blah", undef, undef, 17 );',
    # test aioee with too many args -- aioee should choke
    aioeeX1 => '$test->aioee( 1..16 );',
    # test aioee with input only -- aioee should choke
    aioeeX2 => '$test->aioee( "", "blah" );',
    aioeeX3 => '$test->aioee( "", "blah", undef, undef, undef );',
    # test aioee with an wrong exit code  -- aioee should choke
    aioeeX4 => '$test->aioee( "", "blah", undef, undef, -12 );',
    aioeeX5 => '$test->aioee( "", "blah", undef, undef, 1024 );',
    # test aioee with a time limit
    limit  => '$test->aioee( "", "blah", "blah", undef, undef, time => 2 );',
    # test the loop method
    loop => << '        EOT',
        @tests = (
            [  "", "foo\nbar\nbaz\n",   "foo\nbar\nbaz\n" ],
            [  "", "fim\nfang\nfoom\n", "boom\n" ],
        );
        $test->loop( @tests );
        EOT
);

