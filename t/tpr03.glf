=begin conf

PGAS = http://perlgolf.sourceforge.net/cgi-bin/PGAS/
version = $Revision $

=head1 The Monthly Course: Mathemathics

=begin hole cantor

id = 4

=end hole

=head1 Hole1: Cantor

Display the Cantor set. This is one of the simplest fractals, discovered
by Georg Cantor. It is the result of an infinite process, so for this
hole, printing an approximation of the whole set is enough.

The argument passed to your script will be a single digit between 0 and 8
inclusive indicating the order of the approximation.

The following steps describe one way of obtaining the desired output:

=over 4

=item 1.

Start with a string of dashes, with length 3**$ARGV[0].

=item 2.

Replace the middle third of the line of dashes with spaces. You are
left with two lines of dashes at each end of the original string.

=item 3. 

Replace the middle third of each line of dashes with spaces. Repeat
until ready.

For example, if the argument is 3, start with a string of 27 dashes:

    ---------------------------

Remove the middle third of the string:

    ---------         ---------

and remove the middle third of each piece:

    ---   ---         ---   ---

and again:

    - -   - -         - -   - -

The process stops here, when the lines of dashes are all of length 1.

You should not print the intermediate steps. Only the final result, given
by the last line above, should be displayed. Your output should be
properly newline-terminated.

=cut

#
# Here is the Games::Golf interface compatible code to test the entries
#

my @tests = ( 
    [0,"-\n"],
    [1,"- -\n"],
    [2,"- -   - -\n"],
    [3,"- -   - -         - -   - -\n"],
    [4,"- -   - -         - -   - -                           - -   - -         - -   - -\n"],
    [5,"- -   - -         - -   - -                           - -   - -         - -   - -                                                                                 - -   - -         - -   - -                           - -   - -         - -   - -\n"]
);

# Ok, here's the real thing.
$test->compile;           # at least.
foreach my $set ( @tests ) {
    $test->aioee( "", $set->[0], $set->[1], "", undef );
}

=begin hole kola

id = 3

=end hole

=head1 Hole 2: Kolakoski

Print a Kolakoski sequence. This is a sequence of numbers that describes
itself.

The string "122112122122112..." consists of alternating substrings of
1's and 2's: "1", "22", "11", "2", "1", ... . If you write down
the lengths of these substrings: 1, 2, 2, 1, 1, ..., you get the numbers
in the original string back. A string of numbers with this property is
called a Kolakoski sequence.

You can make a Kolakoski sequence of any two numbers from 1 to 9. For
example, the following is the Kolakoski sequence of 3 and 4:
"33344433344443333...". All Kolakoski sequences are uniquely defined by
the two alternating numbers, and are infinitely long.

Your script should take exactly three arguments. The first two are the
numbers that should be used in the Kolaski sequence. They are two distinct
numbers between 1 and 9 inclusive, written as single digits. The third
argument will be a number between 1 and 500 inclusive. It is the number of
characters that should be printed. Your program must print exactly that
number of characters, no more and no less, followed by a newline
character.

=cut

#
# Here is the Games::Golf interface compatible code to test the entries
#

my @tests = (
    [ "2 3 20", "22332223332233223332\n" ],
    [ "2 3 21", "223322233322332233322\n" ],
    [ "2 3 22", "2233222333223322333222\n" ],
    [ "2 3 23", "22332223332233223332223\n" ],
    [ "3 2 23", "33322233322332233322233\n" ],
    [ "4 5 25", "4444555544445555444445555\n" ],
    [ "9 8 50", "99999999988888888899999999988888888899999999988888\n" ],
    [ "2 3 1", "2\n" ],         # short lengths
    [ "2 3 2", "22\n" ],        # short lengths
    [ "2 3 3", "223\n" ],
    [ "1 2 20", "12211212212211211221\n"],  # first argument = 1
    [ "1 5 20", "15555511111555551111\n"],
    [ "1 2 1", "1\n" ],
    [ "2 1 300", "221121221221121122121121221121121221221121221211211221221121221221121121221211221221121221221121122121121221221121121221121122121121122122112122121122122121121122122112122121121122121121221121121221211221221121221221121121221121122122121121221121122121121122122121121221121121221221121221211211221221\n" ]
);

# Ok, here's the real thing.
$test->compile;           # at least.
foreach my $set ( @tests ) {
    $test->aioee( "", $set->[0], $set->[1], "", undef );
}

__END__

=head1 General rules

=over 4

=item o 

The programs can be written as one or more lines. The score is the
total number of characters you need (smaller is better). If your
program is more than one line, you must count the newlines in between
as one character each. The #! line is not counted. If you use options
on the #! line, the options themselves are counted, including the
leading space and "-".

=item o 

Your final score is the sum of the scores for both holes. If two (or
more) golfers have the same total score for the two holes, the golfer
with the lowest tie break score wins.

The tie break score is calculated for each script separately as

    $tie  = ( () = $code =~ /\w+|\W+/g ) / (2*length $code);

This counts the number of alternating \w+ and \W+ substrings. For
example, the script

    $foo='bar';print

has the substrings "$", "foo", "='", "bar", "';" and "print", and
results in a tie break score of 6/(2*16).

The two tie break scores are summed to give the overall tie break
score.

=item o 

All programs must work on perl 5.6.1.

=item o 

Assume total memory is < 2**32 bytes. The runtime of your programs
should be finite. If your program takes more than a reasonable time to
run, the validation of your solution by the referees can of course
take more time than usual.

=item o 

The programs may only use the perl executable, no other executables on
the system are allowed (the program may use itself though). You may
use any of the perl 5.6.1 standard core modules (perldoc perlmodlib
for a list of those core modules). Your solutions must be portable in
the sense that it should work on all versions of 5.6.1 everywhere
(however, it's perfectly fine to abuse perl 5.6.1 bugs).

=item o 

When tested, your scripts will be named cantor.pl and kola.pl, and you
must assume your script to have file permissions of 0644 (ie,
non-executable for windows folks).

=back

=head1 Deadline

The game starts May 1st (00:00 UTC) and ends May 8th (00:00 UTC).

=head1 Test program

A test program is provided to help screen entries.

Any program that passes the test program should be submitted. If you are
surprised that your solution passed the test program, please submit it
anyway! That will help us identify bugs in the test program.

For the test program to work correctly, you will have to name your scripts
cantor.pl and kola.pl and place them in the same directory as your test
program. Run the test program:

    $ perl tpr03.pl

to verify that your entries are valid. The test script can detect if you
have only provided a solution for one of the holes, and in that case will
check that hole only.

Passing the test program does not assure your solution is valid. The
referees have the final say.

=head1 Submitting

You can submit your solutions here (you'll notice it's the same page as
the Leaderboard). You should not submit solutions for both holes at the
same time. Only golfers that have solved both holes will appear on the
Leaderboard.

Do not publish your solutions anywhere. That will spoil the game, as your
solutions are meant to be secret. All solutions will be published at the
end of the game.

Prizes (provided by O'Reilly and ActiveState) will be awarded to veteran
and beginner winners. A prize may also be awarded to any especially
interesting artistic and/or unorthodox solutions.

=head1 Leaderboard

You can track your ranking through the leaderboard here. Beginners are
encouraged to enter and there is a separate leaderboard for them.

New this month is a special board for teams. There will be no prizes
awarded to the best team, other than the admiration of your fellow
golfers. If you are in a team, you can't also play individually.

=head1 Feedback

We encourage you to send feedback as well as your ideas for future holes
and tiebreakers to golf@theperlreview.com. Your feedback about
Games::Golf should directly go to the developpers list:
games-golf-cvs@mongueurs.net.

=head1 Referees

=over 4

=item o 

Eugène van der Pijll E<lt>pijll@phys.uu.nlE<gt>

=item o 

Yanick Champoux E<lt>yanick1@sympatico.caE<gt>

=item o 

Keith Calvert Ivey E<lt>kcivey@cpcug.orgE<gt>


=item o 

Stefan `Sec` Zehl E<lt>sec@42.orgE<gt>

=item o 

Jason Henry Parker E<lt>jasonp@uq.net.auE<gt>

=back

If you want to be a referee next month, drop us a note:
golf@theperlreview.com

=cut

# Change this if your scripts are at another location.
# Remember that your scripts when tested by the referees
# will be named cantor.pl and kola.pl
my @scripts = qw/cantor.pl kola.pl/;


#----------------------------------------------------------#
#          You should not modify after this line.          #
#----------------------------------------------------------#



# Catching STDERR.
my $ERR = "err.tmp";

my (@skipped, @failed);
HOLE:
foreach my $script ( @scripts ) {
    if (!-e $script) {
        print "Skipped $script\n";
        push @skipped, $script;
        next;
    }
    foreach my $test ( @{$tests{$script}} ) {
        # Prepare command.
        my $cmd = qq("$^X" $script $test->[0] 2>$ERR);
        print "Running '$cmd':\t";
        my $out = `$cmd`;

        # Check STDERR.
        if ( -s $ERR ) {
            print "oops, you wrote to stderr.\n";
            open ERR, "<$ERR" or die $!;
            local $/;               # slurp mode
            my $err = <ERR>;        # dump error output.
            close ERR;
            unlink $ERR;
            print "STDERR output:\n";
            print  "--\n".$err."--\n";
            print "Failed.\n";
            push @failed, $script;
            next HOLE;
        }

        # Check STDOUT.
        if ( $out ne $test->[1] ) {
            print "oops, wrong output.\n";
            print "Expected:\n";
            print "--\n".$test->[1]."--\n";
            print "Got:\n";
            print "--\n".$out."--\n";
            unlink $ERR;
            print "Failed.\n";
            push @failed, $script;
            next HOLE;
        }
        print "done.\n";
    }
}
unlink $ERR;

print "Skipped: @skipped\n" if @skipped;
exit if @failed;
print "Hooray, you passed.\n" unless @skipped;
print "You shot a round of $total_score strokes.\n";
print "(The decimal part is your tie break score.)\n";
print "You can submit your solution at: http://perlgolf.sourceforge.net/cgi-bin/PGAS/leader.cgi?course=3\n" unless @skipped;
exit;

#
# Compute golf score.
sub get_golf_score {
    my $script = shift;

    my $code;
    open F, "<$script" or die $!;
    {
        local $/;
        $code = <F>;
    }
    close F;
    
    $code =~ s/\r/\n/g;
    $code =~ s/\n+/\n/g;
    $code =~ s/\n+$//;           # Free last newline.
    $code =~ s/^#!\S*perl//;     # Shebang.
    $code =~ s/\n//;             # Free first newline.
    my $score = length $code;

    # Compute tie-breaker.
    my $tie  = ( () = $code =~ /\w+|\W+/g ) / (2*length $code);
    $tie    = .49 if $tie > 0.49;
    $score  += $tie;
    return sprintf "%0.2f", $score;
}

__END__

