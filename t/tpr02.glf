=begin conf

PGAS = http://perlgolf.sourceforge.net/cgi-bin/PGAS/
version = $Revision: 1.4 $

=end conf

=begin hole anagrams

id = 2

=end hole

=head1 The Monthly Hole: Anagrams

=head2 Goal

Find all the anagrams of a given input and display them.

An anagram is a word (or phrase, but we'll stick with words for this
contest) formed by rearranging the letters of another word (or
phrase). For exampe, Elvis to Lives.

=head2 Rules

=over 4

=item o

The program is a filter: it must read from STDIN, and send
output to STDOUT.

=item o

The input file is a text file of words, one word per line.
Each word consists of [a-z] only.

=item o

Each input line consists of the word only, with no leading or trailing
whitespace, and no empty lines.

=item o

All input lines are properly newline terminated, and do not contain
binary 0.

=item o

You may assume ASCII as the character set but you may not use
Unicode-specific semantics.

=item o

All input files have a total size so that they will fit comfortably in
memory and still allow you ample memory to play with.  Please note
that the input file can be empty.

=item o

You may B<not> assume that input file will be sorted.

=item o

You are to print the anagrams found, one line for each combination of
the same letters.

=item o

You are to print the anagrams and only the anagrams: you are to
discard standalone words with no anagrams.

=item o

A line of output consists of all the words that anagrams the others:
each word is separated by one space (no leading/trailing space
allowed).

=item o

The words on each output line will be sorted alphabetically.

=item o

All output lines must be properly newline terminated.

=item o

The output lines are first sorted by number of words (the fewer
first), then alphabetically using the first word.

=item o

You must not write to STDERR.

=item o

The program return code does not matter.

=item o

The average runtime of the program must be finite, but may be
arbitrarily long.

=item o

The program can be written as one or more lines. The score is the
total number of characters you need (smaller is better). If your
program is more than one line, you must count the newlines in between
as one character each. The #! line is not counted. If you use options
on the #! line, the options themselves are counted, including the
leading space and C<->.

=item o

If two (or more) identical solutions are submitted, there is a
tie. For solutions that have the same score with different characters,
this month's tiebreaker is related to anagrams, and will favor the
script with the smallest number of different characters.

=item o

All programs must work on
L<perl 5.6.1|http://www.perl.com/pub/a/language/info/software.html>
(most likely programs you write on another version will be just fine,
so don't directly go downloading a different perl).

=item o

Assume total memory is < 2**32 bytes (this e.g. implies sizes of
arbitrary datastructures can be represented in a plain integer, and
that you must not try to generate arbitrarily big datastructures).

=item o

The program may only use the perl executable, no other executables on
the system are allowed (the program may use itself though). You may
use any of the perl 5.6.1 standard core modules (C<perldoc perlmodlib>
for a list of those core modules). Your solution must be portable in
the sense that it should work on all versions of 5.6.1 everywhere
(however, it's perfectly fine to abuse perl 5.6.1 bugs).

=item o

When tested, your script will be named anagrams.pl, and you must
assume your script to have file permissions of 0644 (ie,
non-executable for windows folks).

=back

=head2 Example

Given the input:
  hack
  snooped
  tables
  salt
  spiff
  feeling
  spooned
  last
  grep
  bleats
  gas
  ablest
  fleeing
  stable
  slat
  drive

You are to output the following:
  feeling fleeing
  snooped spooned
  last salt slat
  ablest bleats stable tables

=cut

#
# This file is the test file, compliant with the Games::Golf module
# interface, for tpr02 golf contest: anagrams.
#

# The whole set of tests.
my @set =
  (
# void input.
[ "", ""],

# standard input: mixed order, anagrams and single words.
[ "hack
snooped
tables
salt
spiff
feeling
spooned
last
grep
bleats
gas
ablest
fleeing
stable
slat
drive
",
"feeling fleeing
snooped spooned
last salt slat
ablest bleats stable tables
" ],

# input with no anagrams.
[ "eugene
andrew
ton
fwp
spiff
mtv
",
"" ],

# input with only anagrams of the same letters.
[ "partisans
aspirants
",
"aspirants partisans
" ],

# melting words.
[ "evidence
acres
fizzle
loner
siren
snuggled
foo
sierra
salter
evaporate
ourselves
counterflow
unwelcome
sects
severities
nicest
flint
familiarizing
unknowable
archbishop
encrypt
alerts
cares
races
scare
airers
yelp
ariser
nip
ensure
raiser
warfield
quashing
emil
slater
romeo
pier
engenders
nanoprogramming
alters
railroading
discounts
jacky
resin
barefaced
champion
sued
uwarn
foo
streetcars
ached
dues
rinse
audiogram
necessitated
derivatives
editorial
loophole
deus
snobbish
identifiably
inconceivable
used
pinkly
genoa
risen
decisiveness
misshapen
reins
large
neil
foreseen
rebuttal
deletions
slack
",
"foo foo
acres cares races scare
airers ariser raiser sierra
alerts alters salter slater
deus dues sued used
reins resin rinse risen siren
" ],

# more and less than 10
["foo
azzz
oof
ter
larrywall
arrywalll
rrywallla
rywalllar
ywalllarr
walllarry
alllarryw
lllarrywa
llarrywal
llawyrral
lawyrrall
",
"foo oof
alllarryw arrywalll larrywall lawyrrall llarrywal llawyrral lllarrywa rrywallla rywalllar walllarry ywalllarr
"],
);

# Ok, here's the real thing.
$test->compile;           # at least.
$test->limit(time => 5);  # should be enough.
foreach my $set ( @set ) {
    $test->aioee( "", $set->[0], $set->[1], "", undef );
}

__END__

=head2 Deadline

The game starts April 1st (00:00 UTC) and ends April 8th (00:00 UTC).

=head2 Test program

A L<test program|http://perlgolf.sourceforge.net/TPR02/tpr02.pl> is
provided to help screen entries.

Any program that passes the test program should be submitted. If you
are surprised that your solution passed the test program, please
submit it anyway! That will help us identify bugs in the test program.

For the test program to work correctly, you will have to name your
script anagrams.pl and place it in the same directory as your test
program. Run the test program:

    $ perl tpr02.pl

to verify that your entry is valid.

Passing the test program does not assure your solution is valid. The
referees have the final say.

=head2 Submitting

You can submit your solution
L<here|http://perlgolf.sourceforge.net/cgi-bin/PGAS/leader.cgi?course=2>
(you'll notice it's the same page as the Leaderboard).

Do not publish your solutions anywhere. That will spoil the game, as
your solutions are meant to be secret. All solutions will be published
at the end of the game.

=head2 Leaderboard

You can track your ranking through the leaderboard
L<here|http://perlgolf.sourceforge.net/cgi-bin/PGAS/leader.cgi?course=2>.
Beginners are encouraged to enter and there is a separate leaderboard for
them.


=head2 Feedback

We encourage you to send feedbacks as well as your ideas for holes and
tiebreakers to L<golf@theperlreview.com|mailto:golf@theperlreview.com>.

=head2 Referees

=over 4

=item o

Dave Hoover <squirrel@cpan.org>

=item o

Peter Makholm <peter@makholm.net>

=item o

JE<eacute>rE<ocirc>me Quelin <jquelin@cpan.fr>

=back

As time goes by, perl golf becomes more and more popular; and we fear
that the number of golfers and submitted solutions explodes, so we
won't be able to perform our task the right way. That's why we'd like
to have a "pool of referees", where people will tell us that they're
ok to be referees from time to time. This would allow us to correctly
handle all the solutions of a tournament asap (since we'll be about 3
or 4 referees for each contest), and still allow the referees to be
golfers the next month.

If you'd like to be a I<part-time referee>, drop us a note:
L<golf@theperlreview.com|mailto:golf@theperlreview.com>.

