#-*- perl -*-
#
# Copyright (c) 2002
#          Philippe 'BooK' Bruhat <book@cpan.org>
#          Dave Hoover            <dave@redsquirreldesign.com>
#          Steffen Müller         <games-golf@steffen-mueller.net>
#          Jonathan E. Paton      <jonathanpaton@yahoo.com>
#          Jérôme Quelin          <jquelin@cpan.org>
#          Eugène Van der Pijll   <E.C.vanderPijll@phys.uu.nl>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# $Id: TestSuite.pm,v 1.46 2002/03/10 11:03:54 jep Exp $
#
package Games::Golf::TestSuite;

use strict;

# Modules we rely upon.
use Carp;
use File::Basename;
use IO::Select;
use IPC::Open3;
use POSIX qw(tmpnam);

# Variables of the module.
local $^W = 1;    # use warnings for perl < 5.6

=head1 NAME

Games::Golf::TestSuite - An object that can run a suite of tests.

=head1 SYNOPSIS

  use Games::Golf::TestSuite;

  my $test   = new Games::Golf::TestSuite( "hole" );
  my $result = $test->check( $entry );

=head1 DESCRIPTION

!!FIXME!!

=head2 Methods

=over 4

=item $test = Games::Golf::TestSuite->new( "hole.t" );

Constructs a Games::Golf::TestSuite object with the tests held in
the file given as an argument.

A test suite is a perl script written as follow:

 # first test: does the script at least compile?
 $test->compile;
 # check 
 $in   = 'some input to give the script';
 $out  = 'the script expected output';
 $err  = '';    # don't expect anything on STDERR
 $exit = undef; # don't care for exit code
 $test->aioee( $args, $in, $out, $err, $exit );

 # use other Games::Golf::TestSuite method
 # to create as many subtests as needed

=cut

sub new {
    my $class = shift;
    my $file  = shift;
    my $self  = bless {
        file  => $file,
        hole  => basename($file),
        limit => {
            time   => undef,
            stdout => undef,
            stderr => undef,
            opcode => undef,
          },
    }, $class;

    # read the code from the file
    my $testsuite;
    {
        local $/ = undef;
        open TESTSUITE, "< $file" or croak "Can't open testsuite file '$file': $!";
        $testsuite = <TESTSUITE>;
        close TESTSUITE or carp "Could not close testsuite file '$file': $!";
    }

    # create the coderef
    $self->{testsuite} = eval << "    EOT";
    sub {
        no strict;
        local \$^W;
        my \$test = shift; # this is the Games::Golf::TestSuite
        # create a "sandbox", so as to avoid variable conflicts
        package Games::Golf::TestSuite::Sandbox;
        # insert the test code
        $testsuite;
    }
    EOT

    # report the compilation errors
    croak "Can't compile $file: $@" if $@;

    # Return the new object.
    return $self;
}

=item $test->limit( time => 30, stdout => 1024, stderr => 1024 );

Sets limits on the scripts under test.

!!FIXME!! More documentation here.

=over 4

=item time

A time limit for each test (default unlimited).

=item stdout and stderr

A data limit for stdout and stderr (default unlimited).

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
        my $attr = lc(shift) || "undef";

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
            my ($attr, $value) = splice (@_, -2);
            $attr = lc $attr || "undef";

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

=item $test->run( @entries );

Run the testsuite on the given list of Games::Golf::Entry objects.
This method simply loops on C<@entries> with check() method.

=cut

sub run {
    my ($self, @entry) = @_;
    $self->check($_) foreach (@entry);
    return undef; # Protect against implicit return value
}

=item $test->check( $entry );

Run the testsuite on a single Games::Golf::Entry object, update the
object and return the results of the test. The C<result> attribute
of the C<Games::Golf::Entry> object is updated.

=cut

sub check {
    my ( $self, $entry ) = @_;

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
    # and make sure we don't destroy a file by the same name
    my $tmpfile = '';
    if( -e "$self->{file}.pl" ) {
        # rename the file
        $tmpfile = "$self->{file}." . time;
        rename( "$self->{file}.pl", $tmpfile )
            or croak "Could not rename $self->{file}.pl to $tmpfile";
    }
    open F, "> $self->{file}.pl" or croak "Can't open $self->{file}.pl: $!";
    print F $entry->code;
    close F;

    # run the testsuite (emulating a method call)
    {
        no strict;
        local $^W;
        $self->{testsuite}($self);
    }

    # cleanup after
    # !!FIXME!! duplicated code
    delete @{$self}{ 'code', 'sub', 'entry' };
    *{"Games::Golf::TestSuite::Sandbox::$self->{hole}"} = sub { };

    # put things back to normal
    unlink "$self->{file}.pl"
        or carp "Couldn't unlink temporary file $self->{file}.pl!";
    if( $tmpfile ) {
        rename( $tmpfile, "$self->{file}.pl" )
            or croak "Could not rename $tmpfile to $self->{file}.pl";
    }

    # return the results from the Games::Golf::Entry object
    return $entry->result;
}

=back

=head2 Available tests for testing scripts

These tests are Games::Golf::TestSuite methods that hole makers can use
in their hole test scripts.

=over 4

=item $test->compile;

Does the player script at least compile?
This does count as a test in the testsuite.

=cut

sub compile {
    my $self = shift;
    my $file = $self->{file} . ".pl";

    qx("$^X" -c $file);
    my $exit = $? >> 8;

    # Did it work?
    # !!FIXME!! How do we get the full error message, now?
    $self->{entry}->ok( !$exit, "Script doesn't compile!" );
}

=item $test->aioee( $args, $in, $out, $err, $exit );

Given C<$args> and C<$in>, the script should output C<$out> on STDOUT,
C<$err> on STDERR and exit with code C<$exit>. If you don't care about
any of the three outputs (stdout, stderr or exit code), just pass C<"">
or C<undef> instead.


B<WARNING!> This sub is a minimal workaround, and may deadlock on big
input sets, since we do not check via select if we can write.

=cut

sub aioee {
    my ( $self, $args, $in, $out, $err, $exit ) = @_;

    my ($timeout) = $self->limit("time");

    unless ( defined($out) or defined($err) or defined($exit) ) {
        # Nothing to check: why the hell did the referee did this test?
        # Return immediate success. !!FIXME!! or failure?
        $self->{entry}->ok( 1 );
        return;
    }

    # Fetch file information.
    my $file = $self->{file} . ".pl";
    my $in_file  = tmpnam();
    my $err_file = tmpnam();

    # Store input.
    open IN, ">$in_file" or croak $!;
    print IN $in;
    close IN;

    # Launch command.
    my $stdout;
    my $cmd = qq("$^X" $file $args <$in_file 2>$err_file);

    if ( $^O eq 'MSWin32' or not defined $timeout) {
        # Windows... Sigh. Launch commands at your own risks.
        # But you are already familiar with the risks since you
        # run windows, aren't you? :)
        $stdout = `$cmd`;

    } else {
        # There's a unix smell near there...
        # Let's play with alarms...
    
        eval {
            local $SIG{ALRM} = sub { die "timeout"; };
            alarm($timeout);
            $stdout = qx($cmd);
            alarm(0);
        };
        if ($@) {
            if ($@ =~ /timeout/ ) {
                # Timed out! 
                # Bad guy who tried to stick our machine.
                $self->{entry}->ok( 0, "Oops, timed out $timeout"
                                     . "seconds) while running script." );
                return;

            } else {
                # We should not get there, should we?
                alarm(0); # Clear the still pending alarm.
                croak;    # Propagate unexpected exception.
            }
        }
    }

    # Fetch results.
    my $ec = $? >> 8;
    my $stderr;
    {
        local $/;
        open ERR, "<$err_file" or croak $!;
        $stderr = <ERR>;
        close ERR;
    }
    unlink $in_file;  # We live in a clean world.
    unlink $err_file; # Do not leave garbage.
    

=pod

    use constant SELECT_TIMEOUT => 0.05;

    my $file = $self->{file} . ".pl";
    my ($pid, $ec);

    # Restrictions to apply
    my %limit = 
      ( time   => 30,           # 30 Seconds
        stdout => 1000000,      # 1  Megabyte
        stderr => 1000000,      # 1  Megabyte
        @_
      );

    croak "Invalid parameters passed!"
      unless (scalar keys %limit == 3);

    # Storage for data read
    my ($stdout, $stderr) = ("", "");

    # Use exceptions
    eval {
        # Start code under test
        local (*IN, *OUT, *ERR);
        $pid  = open3(\*IN, \*OUT, \*ERR, "$^X $file");

        # Use select to monitor filehandles
        my $select = IO::Select->new;
        $select->add(\*OUT, \*ERR); # do not check \*IN.

        # Do writing.
        print IN $in;
        close IN;

        waitpid($pid, 0);
        $ec = $? >> 8;

        # Do reading
        while ( my @ready = $select->can_read(SELECT_TIMEOUT) ) {

            foreach my $fh ( @ready ) {
                # from STDOUT
                if ($fh == \*OUT) {
                    $stdout .= <OUT>;
                }
                # from STDERR
                elsif ($fh == \*ERR) {
                    $stderr .= <ERR>;
                }
                $select->remove($fh) if eof($fh);
            }
        }
        #waitpid($pid, 0);

        close OUT;
        close ERR;
    };

    # Handle exceptions (TODO)
    #if ($@) {
    #die $@;
    #}

=cut

    # one more test.
    my $success = 1;
    my $msg     = "";

    if ( defined($out) and $stdout ne $out ) {
    # Ooops, wrong output.
        $success = 0;
        $msg = "Oops, wrong output.\nExpected:\n--\n".$out."--\nGot:\n--\n".$stdout."--";
    } 

    if ( defined($err) and $stderr ne $err ) {
        # Ooops, wrong stderr.
        $success = 0;
        $msg = "Oops, wrong stderr.\nExpected:\n--\n".$err."--\nGot:\n--\n".$stderr."--";
    } 

    if ( defined($exit) and $ec != $exit ) {
        # Ooops, wrong exit code.
        $success = 0;
        $msg = "Oops, wrong exit code. Expected: $exit, got: $ec";
    }

    # Store result of the test.
    $self->{entry}->ok( $success, $msg );
}

=head2 Available tests for testing subs

If the hole requires a sub, the testsuite must first create the
sub with makesub(), and then can use it.

The sub is stored in the C<sub> attribute of the Games::Golf::TestSuite
object, and is named after the hole, in the Games::Golf::TestSuite::Sandbox
package (in case the sub calls itself).

=item $test->makesub;

Create a subroutine named after the hole in the sandbox.
It can then be used through C<$test-E<gt>sub( ... )> or by calling it
directly by its name (the hole name).

This does count as a test in the testsuite. The sub should at least be
valid Perl, shouldn't it?

=cut

sub makesub {
    my $self = shift;
    my $sub  = eval "sub { $self->{code} }";

    # did it compile?
    $self->{entry}->ok( !$@, $@ );

    # finally store the coderef (might be undef)
    $self->{sub} = $sub;

    # does nothing if $sub is undef
    no strict 'refs';
    local $^W;    # don't warn about redefined subs
    *{"Games::Golf::TestSuite::Sandbox::$self->{hole}"} = $sub;
}

=item $test->sub( ... );

Call the subroutine defined with makesub().

=cut

sub sub {
    my $self = shift;
    $self->{sub}(@_) if defined $self->{sub};
}

=item $test->ok( $result, $expected );

Similar to the ok() sub used in the Test module.
The two parameters are in scalar context.

The following examples are straight from Test.pm:

 $test->ok(0,1);             # failure: '0' ne '1'
 $test->ok('broke','fixed'); # failure: 'broke' ne 'fixed'
 $test->ok('fixed','fixed'); # success: 'fixed' eq 'fixed'
 $test->ok('fixed',qr/x/);   # success: 'fixed' =~ qr/x/

 $test->ok(sub { 1+1 }, 2);  # success: '2' eq '2'
 $test->ok(sub { 1+1 }, 3);  # failure: '2' ne '3'
 $test->ok(0, int(rand(2));  # (just kidding :-)

 $test->ok 'segmentation fault', '/(?i)success/'; # regex match

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

These tests are Games::Golf::TestSuite methods that hole makers can use
in their hole test scripts.

The subtests use the code stored in attribute C<code>, and update
the attribute C<result>.

=item $test->not_string( $s );

Test that the code in the entry doesn't contain the string C<$s>.

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

Test that the code in the entry doesn't use the given opcode. (TODO)

=cut

1;

__END__

=back

=head1 BUGS

Please report all bugs to:

http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-Golf

=head1 TODO

Arrange for the entry script to be run with use strict; and warnings.
(right now, they are run in a no strict, no warnings sandbox.)

=head1 AUTHORS

=over 4

=item Philippe 'BooK' Bruhat E<lt>book@cpan.orgE<gt>

=item Dave Hoover            E<lt>dave@redsquirreldesign.comE<gt>

=item Steffen Müller         E<lt>games-golf@steffen-mueller.netE<gt>

=item Jonathan E. Paton      E<lt>jonathanpaton@yahoo.comE<gt>

=item Jérôme Quelin          E<lt>jquelin@cpann.orgE<gt>

=item Eugène Van der Pijll   E<lt>E.C.vanderPijll@phys.uu.nlE<gt>

=back

=head1 COPYRIGHT

This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>, L<Games::Golf>, L<Games::Golf::Entry>.

=cut


