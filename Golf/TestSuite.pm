#-*- perl -*-
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# $Id: TestSuite.pm,v 1.97.2.1 2002/05/15 21:54:32 book Exp $
#
package Games::Golf::TestSuite;

use 5.005;
use strict;
local $^W = 1; # Enable warnings the old way

use Games::Golf::OS qw/ :functions /;

use Carp;
use File::Basename;
use File::Temp qw/ tempfile mktemp /;
use File::Spec;

use IO::File;
use IO::Select;
use IPC::Open3;
use POSIX qw( :sys_wait_h );

use constant IO_TIMEOUT   => 0.05;
use constant IO_BLOCKSIZE => 1024;

# the various implementations of the capture() method
my %capture = (
   unix          => \&_capture_unix,
   unix_nolimit  => \&_capture_unix_nolimit,
   winnt_nolimit => \&_capture_winnt_nolimit,
   win9x_nolimit => \&_capture_win9x_nolimit,
);

# temporary files template, for use with File::Temp
my $template = File::Spec->canonpath( (File::Spec->tmpdir() || ".")             
                                      . "/golfXXXX" );      

=head1 NAME

Games::Golf::TestSuite - Class that can run test suites

=head1 SYNOPSIS

    use Games::Golf::TestSuite;

    my $test = new Games::Golf::TestSuite( $hole );
    $test->run ( @entries );

=head1 DESCRIPTION

A Perl Golfer, ensnared by the powerful desire to eliminate
characters, avoids good programming practice.  He uses, and
abuses, any obscure functions and features that can be
found.  After much agony, he asks himself "Does it work?"

Without breaking his deep concentration, he wants to check
whether his efforts have paid off - he needs a test script.
Similarily, the game referee needs to know whether a random
character sequence actually solves the problem.  Writing a
test script from scratch can be hard, but we have tackled
the difficult tasks so you don't have to.  A basic test
suite could be written as:

    # Does the solution compile?
    $test->compile;

    # Provide input and expect  output
    $test->aioee("", "stdin", "stdout", "stderr", 0);

Could it get much easier than that?  When the testing
methods of this class are called, the test suite file is
executed, and the results stored in the object attributes.

=head1 CONSTRUCTOR

=over 4

=item new( $testcode, $entryfile )

The constructor reads the test suite code, and the name
of the file that is supposed to store the entry code.
 
Any errors in compilation will result in an exception being
raised.

Full details on how to create test suite files can be found
in the B<UNNAMED> section below.

=cut

sub new {
    my $class = shift;
    my ( $code, $file ) = @_;

    # Create object
    my $self  = bless {
        code  => $code,
        file  => $file,
        limit => {
            time   => undef,
            stdout => undef,
            stderr => undef,
            opcode => undef,
          },
    }, $class;

    # the default implementations depending on the underlying OS
    $self->{arch} = 'unix_nolimit'  if is_Unix; # we don't use limit() for now
    $self->{arch} = 'winnt_nolimit' if is_WindowsNT;
    $self->{arch} = 'win9x_nolimit' if is_Windows9x;

    if (@_ == 2) {

        # Create the coderef (someday we will use Safe)
        $self->{testsuite} = eval << "        EOT";
        sub {
            no strict;
            local \$^W;
            my \$test = shift; # this is the Games::Golf::TestSuite
            # create a "sandbox", so as to avoid variable conflicts
            package Games::Golf::TestSuite::Sandbox;
            # insert the test code
            $code;
        }
        EOT

        # Report any compilation errors
        if ($@) {
            croak "fatal: failed to compile testsuite for '$file':\n$@";
        }
    }

    # Complain about wrong number of parameters
    else {
        croak "fatal: constructor needs two parameters";
    }

    return $self;
}

=back

=head1 LIMITS

Limits are restrictions on how a script can behave.  For
example, setting the C<stdout> limit to C<1024> will kill a
script that tries writing more than 1kB of data to
C<stdout>.

By default, no restrictions are applied and the scripts being
tested can do almost anything.  This is rarely desirable
when testing untrustworthy entries, so limits should be set
whenever possible.

Unfortunately, the ability of limits to function correctly
depends on the operating system used.  Non-Unix systems
may not support them particularly well - if at all.  Users
are strongly advised to read the section on B<PLATFORMS>.

To retrieve or set limits the following accessor is used:

=over 4

=item limit ( [OPTIONS] )

Pass no values to retrieve all limits and their values.

Pass one value to retrieve the values of a single limit.

Pass key/value pairs to set limits, previous values returned
for convience.

=back

The following limits can be set:

=over 4

=item time => integer

Sets an overall time limit on how long a script can run for.

Platform dependent.

=item stdout => integer and/or stderr => integer

A data limit for stdout and stderr.

Platform dependent. (Win9X)

=back

=cut

sub limit {
    my $self = shift;

    # Get all attributes if there are no parameters.
    if (@_ == 0) {
        return %{ $self->{limit} };
    }

    # Get named attribute if one parameter given.
    elsif (@_ == 1) {
        my $attr = lc(shift) || "<undef>";

        if (exists $self->{limit}{$attr}) {
            return $self->{limit}{$attr};
        }
        else {
            croak "Invalid limit type: $attr";
        }
    }

    # otherwise set attributes and return previous values...
    elsif (@_ % 2 == 0) {
        my %prev = $self->limit();

        while (@_ > 0) {
            my ($attr, $value) = splice @_, -2;
            $attr = lc $attr || "<undef>";

            if ($attr eq "time" or $attr eq "stdout" or $attr eq "stderr") {
                croak "Invalid limit value '$value' for $attr"
                    if defined $value and $value !~ /^\d+$/;
                $self->{limit}{$attr} = $value;
            }
            elsif ($attr eq "opcode") {
                carp "Opcode limit not implemented";
            }
            else {
                croak "Invalid limit type: $attr";
            }
        }
        return %prev;
    }

    # but reject unless they come in pairs.
    else {
        croak "Key/value pairs required when setting limits";
    }
}

=over 4

=item arch( [$arch] )

Select the underlying implementation for the capture() method.
This is autoselected by C<Games::Golf::TestSuite>, but bold users
or testers can select the one they want. The method returns the
name of the previously selected implementation.

With no argument given, it returns the currently selected
implementation.

If one tries to select a non-existent implementation, it stays
unchanged.

The C<capture()> method can also decide to use a more appropriate
implementation if it detects possible optimisations.

=back

=cut

sub arch {
    my $self = shift;
    my $new  = shift || "";
    my $old  = $self->{arch};
    if ( exists $capture{$new} ) { $self->{arch} = $new }
    return $old;
}

=head1 METHODS: RUNNING TEST-SUITES ON ENTRIES

These methods either test a single entry, or multiple
entries via the test suite script.  The test results are
stored within the C<Games::Golf::Entry> object, in the
C<result> attribute.

Exceptions may be raised in the event of an error, and will
match /^check:/.

=over 4

=item $test->check( ENTRY );

The test suite will be executed for a single
C<Games::Golf::Entry> object, unless the entry has been
checked previously.  To recheck, you must unset the
C<result> attribute of the C<Entry> object.

The test result is returned (FIXME - what is the result?)

=cut

sub check {
    my ($self, $entry) = @_;

    no strict 'refs';
    local $^W;    # don't warn about redefined subs

    # cleanup before
    delete @{$self}{ 'code', 'sub', 'entry' };
    *{"Games::Golf::TestSuite::Sandbox::$self->{hole}"} = sub { };

    # store various data related to the Entry
    $self->{entry} = $entry;
    $self->{code}  = $entry->code;
    $entry->result( [ 0, 0 ] );

    # save the code to a file
    # but make sure we don't destroy a file by the same name
    my $tmpfile = '';
    if( -e $self->{file} ) {
        # rename the file
        $tmpfile = "$self->{file}." . time;
        rename( $self->{file}, $tmpfile )
            or croak "fatal: could not rename $self->{file} to $tmpfile";
    }
    open F, "> $self->{file}" or croak "fatal: can't open $self->{file}: $!";
    print F $entry->code;
    close F;

    # run the testsuite (emulating a method call)
    eval {
        no strict;
        local $^W;
        $self->{testsuite}($self);
    };

    # cleanup after
    # !!FIXME!! duplicated code
    delete @{$self}{ 'code', 'sub', 'entry' };
    *{"Games::Golf::TestSuite::Sandbox::$self->{hole}"} = sub { };

    # put things back to normal
    unlink $self->{file}
        or carp "Couldn't unlink temporary file $self->{file}!";
    if( $tmpfile ) {
        rename( $tmpfile, $self->{file} )
            or croak "Could not rename $tmpfile to $self->{file}";
    }

    # Did we die while running the testsuite?
    # If this was because of compilation errors in compile()
    # or makesub(), forget it.
    $@ = '' if $@ =~ /^compilation:/;
    # If we did really die, die. For good.
    die "$@\n" if $@;

    # return the results from the Games::Golf::Entry object
    return $entry->result;
}

=item $test->run( [ ENTRIES ] );

Calls the C<check()> method for each C<Games::Golf::Entry>
object passed.  There is no return value.

=cut

sub run {
    my ($self, @entry) = @_;

    foreach my $entry (@entry) {
        next unless $entry->result->[0] == 0;
        $self->check($entry);
    }
    return;
}

# !!DECISION!! Could we make the return value the number of
# entries actually tested (I.e. not skipped), or the number
# that were tested sucessfully?

=back

=head1 METHODS: INDIVIDUAL TESTING

These tests are C<Games::Golf::TestSuite> methods that hole
makers can use in their hole test scripts.

Each of these methods will add to the results already stored
in the C<Entry> object being tested.

=over 4

=item $test->compile;

This checks that the player script will compile.

The exit code from "perl -c" is returned.  This could be
used to short circuit full testing, if required.  This
function is subject to the security issues of the C<capture()>
function - including insecure arguments via filename.

=cut

#!!FIXME!! Needs rewrite to provide useful feedback
#          documentation and code don't match

sub compile {
    my $self = shift;
    my $file = $self->{file};

    my (undef, $stderr, $exit) = $self->capture($^X, "-c $file");

    $self->{entry}->ok(!$exit, "Script doesn't compile!\n" . $$stderr );
    die "compilation: compile() failed!" if $exit;

    return $exit;
}

=item $test->aioee( $args, $in, $out, $err, $exit );

Given C<$args> and C<$in>, the script should output C<$out>
on STDOUT, C<$err> on STDERR and exit with code C<$exit>. If
you don't care about any of the three outputs (stdout,
stderr or exit code), just pass C<""> or C<undef> instead.

!!FIXME!! Rewrite required.
!!FIXME!! Shouldn't aioee automatically set the limits?
          After all, when you give the expected output, the script
          should be killed whenever it prints more than the expected.
          On the other hand, a good error message should print all of
          the incorrect output.

=cut

sub aioee {
    my $self = shift;

    # Get our parameters
    my ($args, $input) = @_;
    my %expect = (
        stdout => $_[2],
        stderr => $_[3],
        exit   => $_[4]
    );

    # Dereference parameters
    foreach my $item ($input, $expect{qw<stdout stderr>}) {
        next unless defined $item and ref $item ne "";    

        die "Invalid reference given as a parameter"
            unless ref $item eq "SCALAR";

        $item = ${ $item };
    }

    # Process our parameters
    # Only the author of the .glf files should see those errors
    die "Too many parameters passed"
        unless @_ <= 5;

    die "At least one type of output must be checked"
        unless defined $expect{stdout}
            or defined $expect{stderr}
            or defined $expect{exit};

    die "Integer between 0 and 255 required when checking exit code"
        unless not defined $expect{exit}
            or $expect{exit} =~ /^\d+$/
           and $expect{exit} <= 255;

    # Prepare command line
    #!!FIXME!! Shell version of quotemeta?
    my $file = $self->{file};
    my $cmd = qq("$^X" $file);

    # Execute command and capture
    my @result = $self->capture($cmd, $args, \$input);
    my %actual = (
        stdout => ${ $result[0] },
        stderr => ${ $result[1] },
        exit   =>    $result[2]
    );

    # Check actual output matches expected output
    my (%fail, $mesg);

    foreach my $pipe (qw<stdout stderr>) {
        next unless defined $expect{$pipe};

        if ($expect{$pipe} ne $actual{$pipe}) {
            $fail{$pipe}++;
            $mesg .= "Wrong output on $pipe:\n"
                  .  "Expected:\n"
                  .     $expect{$pipe} . "\n--\n"
                  .  "Actual:\n"
                  .     $actual{$pipe} . "\n--\n"
                  .  "\n";
        }
    }

    # Provide hints
    $mesg .= "Hint: You have transposed the outputs!\n"
        if keys %fail == 2
            and $actual{stdout} eq $expect{stderr}
            and $actual{stderr} eq $expect{stdout};

    foreach my $pipe (keys %fail) {

        my ($actual, $expect);

        # Check trailing newlines
        ($actual) = $actual{$pipe} =~ /(\n*)$/;
        ($expect) = $expect{$pipe} =~ /(\n*)$/;
        $mesg .= "Hint: Number of trailing newlines varies\n"
            if $actual ne $expect;

        # Check for non-printables (actually just \0)
        ($actual) = $actual{$pipe} =~ tr/\0//;
        ($expect) = $expect{$pipe} =~ tr/\0//;
        $mesg .= "Hint: Found $actual null characters (\\0), when should have have just $expect.\n"
            if $actual != $expect;
    }
        
    # Check exit code
    $mesg .= "Wrong exit code, expected $expect{exit} but received $actual{exit}"
        if defined $expect{exit} and $expect{exit} != $actual{exit};

    # Store result of the test
    if ($mesg eq "") {
        $self->{entry}->ok(1, $mesg);
    }
    else {
        $self->{entry}->ok(0, $mesg);
    }

    return;
}

=back

=head1 Available tests for testing subs

If the hole requires a sub, the testsuite must first create
the sub with makesub(), and then can use it.

The sub is stored in the C<sub> attribute of the
C<Games::Golf::TestSuite> object, and is named after the hole,
in the C<Games::Golf::TestSuite::Sandbox> package (in case the
sub calls itself).

=over 4

=item $test->makesub;

Create a subroutine named after the hole in the sandbox. It
can then be used through C<$test-E<gt>sub( ... )> or by
calling it directly by its name (the hole name).

This does count as a test in the testsuite. The sub should
at least be valid Perl, shouldn't it?

=cut

sub makesub {
    my $self = shift;
    my $sub  = eval "sub { $self->{code} }";

    # did it compile?
    $self->{entry}->ok( !$@, "Subroutine doesn't compile!\n$@" );

    # stop the tests now!
    die "compilation: makesub() failed" if $@;

    # finally store the coderef (might be undef)
    $self->{sub} = $sub;

    # does nothing if $sub is undef
    no strict 'refs';
    local $^W;    # don't warn about redefined subs
    *{"Games::Golf::TestSuite::Sandbox::$self->{hole}"} = $sub;
}

=item $test->sub( ... );

Call the subroutine defined with C<makesub()>.

=cut

sub sub {
    my $self = shift;
    $self->{sub}(@_) if defined $self->{sub};
}

=item $test->ok( $result, $expected );

Similar to the C<ok()> sub used in the C<Test> module.  The two
parameters are in scalar context.

The following examples are straight from Test.pm:

 $test->ok(0,1);             # failure: '0' ne '1'
 $test->ok('broke','fixed'); # failure: 'broke' ne 'fixed'
 $test->ok('fixed','fixed'); # success: 'fixed' eq 'fixed'
 $test->ok('fixed',qr/x/);   # success: 'fixed' =~ qr/x/

 $test->ok(sub { 1+1 }, 2);  # success: '2' eq '2'
 $test->ok(sub { 1+1 }, 3);  # failure: '2' ne '3'
 $test->ok(0, int(rand(2));  # (just kidding :-)

 $test->ok 'segmentation fault', '/(?i)success/'; # regex match

=back

=cut

sub ok ($$$) {
    my ( $self, $result, $expected ) = @_;
    my $ok = 0;

    # where we passed a coderef?
    $result   = ( ref $result   or '' ) eq 'CODE' ? $result->()   : $result;
    $expected = ( ref $expected or '' ) eq 'CODE' ? $expected->() : $expected;

    my ( $regex, $ignore );
    if ( ( ref($expected) || '' ) eq 'Regexp' ) {
        $ok = $result =~ /$expected/;
    }
    elsif ( ($regex) = ( $expected =~ m,^ / (.+) / $,sx )
        or ( $ignore, $regex ) = ( $expected =~ m,^ m([^\w\s]) (.+) \1 $,sx ) )
    {
        $ok = $result =~ /$regex/;
    }
    else {
        $ok = $result eq $expected;
    }

    my $msg = "expected:\n--\n$expected--\ngot:\n--\n$result--\n";

    # update the result
    # (this is getting complicated, with the two ok() methods)
    $self->{entry}->ok( $ok, $msg );
}

=head2 Other test for the code itself

These tests are C<Games::Golf::TestSuite> methods that hole
makers can use in their hole test scripts.

The subtests use the code stored in attribute C<code>, and
update the attribute C<result>.

=over 4

=item $test->not_string( $s );

Test that the code in the entry doesn't contain the string
C<$s>.

=cut

sub not_string {
    my ( $self, $s ) = @_;

    my $msg  = "Oops, you embedded a '$s' in your code.\n";
    my $code = $self->{code};
    $code =~ s/\A.*\n//m;    # Shebang line may contain anything.

    # update the results
    $self->{entry}->ok( index( $code, $s ) < $[, $msg );
}

=item $test->not_match( $regex );

Test that the code in the entry doesn't match C<$regex>.

=cut

sub not_match {
    my ( $self, $regex ) = @_;

    my $msg  = "Oops, your code matched $regex.\n";
    my $code = $self->{code};
    $code =~ s/\A.*\n//m;    # Shebang line may contain anything.

    # update the results
    $self->{entry}->ok( $code !~ /$regex/, $msg );
}

=item $test->not_op( $op );

Test that the code in the entry doesn't use the given
opcode. (TODO)

=back

=head1 ADVANCED METHODS

!!FIXME!! All of this should go at the end of the module file, after
the documentation for TestSuite (aioee, compile, makesub, sub, ok).
Should all this documentation appear in the module documentation?

Most users probably will never require these, but they are available
if necessary.

=over 4

=item $test->capture( $cmd, $args, $input )

The C<capture()> method runs the C<$cmd> program, with the C<$args>
command line arguments (given as a string !!FIXME!! does this always
work?) and the content of C<$input> is sent to its standard input.

C<capture()> returns a list consisting of the script standard
output, standard error and exit code.

This method is used internally by C<aioee()> and C<compile()>.

=begin problem

Each C<_capture> function is likely to return different
exceptions. Capture should pass them on higher, which
currently there are not.  I thought it would be simplier
handling them here, but that breaks the benefit of having it
publicically exposed in a way that is useful.  I guess the
only solution is to move them higher again.

Likely this, or another C<_capture> function will deal with
making the arguments go to defaults.  The lower C<_capture>
functions should not have to do that, it's too much work to
duplicate all over.

Philippe thinks that the _capture_xxx methods should only produce
a limited set of well-defined exceptions (timeout, size exceeded,
and other IO exceptions) that capture should handle correctly.
Fatal errors sould make TestSuite croak (with a reference to the
underlying implementation used), while others (like timeout) should
be correctly handled (the test failed).

=end problem

=cut

sub capture {
    my $self = shift;
    my @temp;

    # optimisations !!FIXME!! Should they be here or somewhere else?
    my $arch  = $self->arch;
    my %limit = $self->limit;
    $arch = 'unix_nolimit' if( $arch eq 'unix'
                               && ! defined $limit{time}
                               && ! defined $limit{stdout}
                               && ! defined $limit{stderr} );
    eval {
        # The arch() accessor is not used on purpose
        @temp = $capture{$arch}->($self, @_);
    };   

    # Exceptions are caught here for a reason... there
    # could be quite a lot of duplication otherwise.  I
    # expect things to move around for a while, until
    # everything settles.

    # Catch exceptions
    if ($@) {
        my ($type, $mesg) = split /: /, $@;

        # Clear any pending alarm

        if ($type =~ /^exception/) {
            $self->{entry}->ok(0, ucfirst $mesg);
            return;
        }
        elsif ($type =~ /^fatal/) {
            croak;
        }
        elsif ($type !~ /flow/) {
            die "Please email authors, an unexpected error occured:\n$@";
        }
    }

    return @temp;
}

=begin comment

Behaviour is undefined for _capture_* methods unless all
parameters are passed and also have correct type:

  $cmd   --> STRING     (FULL PATH PREFERRED)
  $args  --> STRING     (USER ARGUMENTS ONLY)
  $input --> STRING REF

In addition, captured data must be returned in the form:

  Element 0 --> STRING REF of STDOUT captured
  Element 1 --> STRING REF of STDERR captured
  Element 2 --> INTEGER in range 0 to 255

=end comment

=back

=head2 Unix

This is our all bells and whistles capture function, and
should be the safest for referees to use.  At the moment it
has many limitations and bugs.

=begin comment

The combined use of C<limits>, C<exceptions>, C<signals>,
C<sysread>, C<syswrite>, C<IO::Select> and C<IPC::Open3>
has reduced the overall clarity of this function. Read
the appropriate manpages in conjunction with this section.

Events happen asyncroneously, so much of the effort is in
avoiding deadlock.  The inner eval loops around, writing and
reading from the pipes until an exception is caught.

The outer eval safely captures any pending alarm, whether it
is in the inner eval or the outer eval.  This avoids a race
condition if we leave the inner loop via a C<die()>, but
haven't yet stopped the alarm.

By using hashes for the filehandles, select monitors and
captured data, a symbolic token called C<$pipe> has been used,
with values "stdin", "stdout", "stderr".  This removed
duplication of the read from pipe code.

When a pipe closes, it is removed from the C<%fh> hash.  When
there is no filehandles left, we reap the child.

=end comment

=begin problem

If we die from the inner loop we leave a zombie...
collected on the next run, maybe.  This is a bug.

I haven't yet caught, and rebadged, C<open3> exceptions.
These match /^open3/, and should be faily easy to remap.
I've got enough changes to make this time around, without
worrying about details like that.

The alarm isn't currently implemented yet, however there is
the emulated version.  This is fine for most purposes, but a
bad script can lock it forever, e.g.:

  #!/usr/bin/perl
  BEGIN { sleep time };

this only affects C<BEGIN> blocks, AFAIK.  The use of
emulation, without alarm and with this case should be quite
rare.

We need to trap unfriendly signals from the child, such as
SIGPIPE, SIGKILL etc... as far as possible.  For some of
these the only way might be to change the UID of the child,
fork, and then fork again for C<Open3>.  This would add more
code and add complexity - something I'm not in a hurry to do,
especially when there is more important bugs to find.

=end problem

=cut

sub _capture_unix {
    my ($self, $cmd, $args, $$input) = @_;

    # Storage for data captured
    my %captured = (
        stdout => "",
        stderr => "",
        exit   => undef
    );

    # Child process ID, the reaper needs this
    my $pid;

    # Record the start time and runtime limit
    my %time = (
        start => time,
        limit => $self->limit('time')
    );

    # Use exceptions... to catch alarms safely
    eval {

        # Install signal handlers
        local $SIG{ALRM} = sub { die "exception: exceeded allowed time\n" };

        # Use exceptions... for errors
        eval {
            my $reap = undef;
            my $written = 0;

            # Install signal handlers
            # !!FIXME!! Imagine we do the loop, and then die.  We could
            # receive the CHLD signal a miliseconds later, because we are
            # no longer in this scope, the CHLD signal is proprogated 
            # until it terminates the program.
            local $SIG{CHLD} = sub { $reap = 1 };

            # Create filehandles
            my %fh = (
                stdin  => IO::File->new,
                stdout => IO::File->new,
                stderr => IO::File->new
            );

            # Start code under test
            $pid = open3($fh{stdin}, $fh{stdout}, $fh{stderr}, "$cmd $args");

            # Monitor filehandles using select
            my %select = (
                stdin  => IO::Select->new($fh{stdin}),
                stdout => IO::Select->new($fh{stdout}),
                stderr => IO::Select->new($fh{stderr})
            );

            # Read and write until death occurs
            do {

                # Iterate over the pipes
                foreach my $pipe (keys %fh) {

                    if ($pipe eq "stdin") {

                        # Do writing to STDIN
                        if ($select{$pipe}->can_write(IO_TIMEOUT)) {
                            my $bytes = syswrite $fh{$pipe}, $input, IO_BLOCKSIZE, $written;

                            if (defined $bytes) {
                                $written += $bytes;

                                if ($written == length $input) {
                                    close $fh{$pipe}
                                        or die "exception: failed to close $pipe\n";
                                    delete $fh{$pipe};
                                }
                            }
                            else {
                                die "exception: $pipe closed prematurely\n";
                            }
                        }
                    }
                    else {

                        # Do reading from STDOUT and STDERR
                        if ($select{$pipe}->can_read(IO_TIMEOUT)) {
                            my $bytes = sysread $fh{$pipe}, $captured{$pipe}, IO_BLOCKSIZE, length $captured{$pipe};

                            if (defined $bytes) {
                                my $limit = $self->limit($pipe);

                                die "exception: exceeded $pipe limit\n"
                                    if defined $limit and $limit < length $captured{$pipe};

                                if ($bytes == 0) {
                                    close $fh{$pipe}
                                        or die "exception: failed to close $pipe\n";
                                    delete $fh{$pipe};
                                }
                            }
                            else {
                                die "exception: $pipe closed prematurely\n"
                            }
                        }
                    }
                }

                # Apply timeout limit
                if (defined $time{limit}) {
                    die "exception: exceeded allowed time\n"
                        if time > $time{start} + $time{limit};
                }
            }
            until defined $reap and keys %fh == 0;

            # SIGALRM can hit here...
        };
        # SIGALRM can hit here... 
        die $@ if $@;
    };
    my $exception = $@;

    # Purge zombies 
    eval {
        waitpid $pid, WNOHANG;
        $captured{exit} = ($? >> 8);
    };

    # Proprogate most meaningful error message
    die $exception if $exception;
    die $@ if $@;

    #!!FIXME!! Return a 'fatal: ' if open3 fails
    return \$captured{stdout}, \$captured{stderr}, $captured{exit};
}

=begin comment

This method is the basic implementation of C<capture()> under Unix and
Windows systems. It mainly uses redirections to capture STDOUT and STDERR.
The first argument after $self is a boolean that says if the underlying
OS supports the C<cmd 2E<gt>file> construct to capture STDERR to a file.
If false, _capture_nolimit() will not try to use it.

This method is used by _capture_unix_nolimit(), _capture_winnt_nolimit()
and _capture_win9x_nolimit().

=end comment

=cut

sub _capture_nolimit {
    my ( $self, $has_stderr, $cmd, $args, $input ) = @_;
    my ( $fh, $infile ) = tempfile($template);
    my $errfile = mktemp($template);
    my ( $out, $err ) = ( "", "" );

    # concatenate the command-line parameters
    $cmd .= " $args";

    # if there is some input
    if ($input) {
        print $fh $$input;
        $cmd .= " < $infile";
    }
    close $fh;

    $cmd .= " 2> $errfile" if $has_stderr;

    # run the command
    $out = `$cmd`;

    # this is tedious, but...
    if ($has_stderr) {
        local $/;    # slurp
        local *F;
        open F, $errfile
          or croak "fatal: could not open temporay errput file $errfile: $!";
        $err = <F>;
        close F;
        unlink $errfile;
    }

    # cleanup
    unlink $infile;
    return ( \$out, \$err, $? >> 8 );
}

# the unix implementation
sub _capture_unix_nolimit { shift()->_capture_nolimit(1, @_); }

=head2 Windows

Blurb about Windows security.  (Oxymoron).

=cut

=begin problem

Windows systems do not implement C<IO::Select> on anything
other than sockets... but we have pipes.  Alarms are also no
good either, nor signals, so we are forced into writing
specially for Windows/DOS.

=end problem

=cut

# this is mostly the same a unix_nolimit,
# since windows NT supports 2> notation and exit codes
*_capture_winnt_nolimit = \&_capture_unix_nolimit;

# Windows 9x doesn't support STDERR redirections
sub _capture_win9x_nolimit {
    _capture_nolimit( shift, 0, @_ );
}

1;

__END__

=head1 BUGS

Please report all bugs to:

http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-Golf

=head1 TODO

Arrange for the entry script to be run with use strict; and
warnings.  (right now, they are run in a no strict, no
warnings sandbox.)

=head1 AUTHORS

See C<Games::Golf> or the AUTHORS file for the list of authors.

=head1 COPYRIGHT

This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>, L<Games::Golf>, L<Games::Golf::Entry>.

=cut
