# 14unix.t
#
# Low-level Games::Golf::TestSuite methods: _capture_unix()
#
# $Id: 14unix.t,v 1.4 2002/05/12 13:42:25 book Exp $

use strict;
use Test;

use Games::Golf::TestSuite;
use Games::Golf::OS qw/ :functions /;

my $test;
my ($temp, @temp);

#----------------------------------------#
#        Test _capture_unix method       #
#----------------------------------------# 
#                                        #
# Methods called internally:             #
#                                        #
#   limit                                #
#                                        #
# Limits applied:                        #
#                                        #
#   time   - Yes or Partial              #
#   stdout - Yes                         #
#   stderr - Yes                         #
#   opcode - Not implemented (yet)       #
#                                        #
#----------------------------------------#

$test = Games::Golf::TestSuite->new;

use constant UNIX => 1;

# --- Check with valid command ---

eval { @temp = $test->_capture_unix('perl t/valid', "", \"") }
    if UNIX;
skip(!UNIX, $@, '');

# --- Check with invalid command ---

eval { @temp = $test->_capture_unix('perl t/missing', "", \"") }
    if UNIX;
skip(!UNIX, $@, qr!exception: !);

# --- Check with arguments ---

eval { ($temp) = $test->_capture_unix('perl t/args', "--hello", \"") }
    if UNIX;
skip(!UNIX, $@, '');
skip(!UNIX, $$temp, "Hello World\n");

# --- Check normal (small and large input) ---

foreach my $stdin ("DATA", "DATA" x 5000) {

    # Capture (outputs same)
    @temp = $test->_capture_unix('perl t/bounce', '--stdout=right --stderr=right --exit=10', \$stdin) 
        if UNIX;

    # Compare
    my ($stdout, $stderr, $exit) = @temp;
    skip(!UNIX, $$stdout, $stdin);
    skip(!UNIX, $$stderr, $stdin);
    skip(!UNIX, $exit,    10);

    # Capture (outputs different)
    @temp = $test->_capture_unix('perl t/bounce', '--stdout=right --stderr=wrong --exit=5', \$stdin) 
        if UNIX;

    # Compare
    ($stdout, $stderr, $exit) = @temp;
    skip(!UNIX, $$stdout, $stdin);
    skip(!UNIX, $$stderr, $stdin."JUNK");
    skip(!UNIX, $exit,    5);
}

# --- Check early exit (fast exit) ---

eval { @temp = $test->_capture_unix('perl t/dieyoung.1', "", \"") }
    if UNIX;
skip(!UNIX, $@, qr!exception: !);

# --- Check early exit (slow exit) ---

eval { @temp = $test->_capture_unix('perl t/dieyoung.2', "", \"") }
    if UNIX;
skip(!UNIX, $@, qr!exception: !);

# --- Check with stdout/stderr limits ---

foreach my $pipe ("stdout", "stderr") {

    # Set limit
    $test->limit($pipe => 5);

    # Capture (less than limit)
    eval { @temp = $test->_capture_unix('perl t/bounce', '--stdout=right', \"UNDER") }
        if UNIX;

    # No exception
    skip(!UNIX, $@, '');

    # Capture (more than limit)
    eval { @temp = $test->_capture_unix('perl t/bounce', '--stdout=right', \"EXCEED") }
        if UNIX;

    # Get exception
    skip(!UNIX, $@, qr!exception: !);

    # Unset limit
    $test->limit($pipe => undef);
}

# --- Check with time limit (normal) ---

$test->limit(time => 2);

eval { @temp = $test->_capture_unix('perl t/hang.1', "", \"") }
    if UNIX;
skip(!UNIX, $@, qr!exception: !);

# --- Check with time limit (BEGIN{}) ---
# NB: alarm not implemented yet... would just hang.

$test->limit(time => 2);

#eval { @temp = $test->_capture_unix('perl t/hang.2', "", \"") }
#    if UNIX;
#skip(!UNIX, $@, qr!exception: !);

$test->limit(time => undef);

# --- Check with opcode limit ---
# NB: Not implemented

BEGIN {
    # this is Unix only
    if (is_Unix) { plan tests => 0; exit } #23 }
    else { plan tests => 0; exit }
}

