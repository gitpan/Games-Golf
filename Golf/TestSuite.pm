#-*- perl -*-
#
# Copyright (c) 2002
#          Philippe 'BooK' Bruhat <book@cpan.org>
#          Dave Hoover            <dave@redsquirreldesign.com>
#          Steffen Müller         <tsee@gmx.net>
#          Jonathan E. Paton      <jonathanpaton@yahoo.com>
#          Jérôme Quelin          <jquelin@cpan.org>
#          Eugène Van der Pijll   <E.C.vanderPijll@phys.uu.nl>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# $Id: TestSuite.pm,v 1.17 2002/02/26 20:40:47 book Exp $
#
package Games::Golf::TestSuite;

use strict;

# Modules we rely upon.
use Carp;
use File::Basename;
use IO::Select;
use IPC::Open3;
use POSIX ":sys_wait_h";

# Variables of the module.
local $^W = 1;    # use warnings for perl < 5.6

=head1 NAME

Games::Golf::TestSuite - An object that can run a suite of tests.

=head1 SYNOPSIS

  use Games::Golf;

  # "hole" is the file holding the test suite
  my $test = new Games::Golf::TestSuite( "hole" );

  # $entry is a Games::Golf::Entry object
  $test->check( $entry );

=head1 DESCRIPTION

!!FIXME!!

=head2 Methods

=over 4

=item $test = Games::Golf::TestSuite->new( 'hole.t' );

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
 $test->ioee( $in, $out, $err, $exit );

 # use other Games::Golf::TestSuite method
 # to create as many subtests as needed

=cut

sub new {
    my $class = shift;
    my $file  = shift;
    my $self  = bless {
        file => $file,
        hole => basename $file,
    }, $class;

    # read the code from the file
    local $/ = undef;
    open F, "< $file" or croak "Can't open $file: $!";
    my $testsuite = <F>;
    close F;

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
        # return the results
        \$test->{result};
    }
    EOT

    # $@ holds the compilation errors
    croak "Can't compile $file: $@" if $@;

    # Return the new object.
    return $self;
}

=item $test->run( @entries );

Run the testsuite on the given list of Games::Golf::Entry objects.
This method simply loops on C<@entries> with check() method.

=cut

sub run {
    my $self    = shift;
    my @entries = @_;
    for my $entry (@entries) { $self->check( $entry ) }
}

=item $test->check( $entry );

Run the testsuite on a single Games::Golf::Entry object, update the
object and return the results of the test. The C<result> attribute
of the C<Games::Golf::Entry> object is updated.

=cut

sub check {
    my $self  = shift;
    my $entry = shift;

    no strict 'refs';
    local $^W;    # don't warn about redefined subs

    # cleanup before
    delete @{$self}{ 'code', 'sub' };
    $self->{result} = [ 0, 0 ];
    *{"Games::Golf::TestSuite::Sandbox::$self->{hole}"} = sub { };

    # store the $entry code in $self->{code}
    $self->{code} = $entry->code;

    # save the code to a file
    open F, "> $self->{file}.pl" or croak "Can't open $self->{file}.pl: $!";
    print F $entry->code;
    close F;

    # run the testsuite (emulating a method call)
    my $result;
    {
        no strict;
        local $^W;
        $result = &{ $self->{testsuite} } ($self);
    }

    # set the result in the Games::Golf::Entry object
    $entry->result($result);

    # cleanup after
    # !!FIXME!! duplicated code
    delete @{$self}{ 'code', 'sub' };
    $self->{result} = [ 0, 0 ];
    *{"Games::Golf::TestSuite::Sandbox::$self->{hole}"} = sub { };
    unlink "$self->{file}.pl";

    # return the results
    return $result;
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

    # !!FIXME!! does in work under Win32?
    # couldn't we fork a child and read its STDERR
    # directly?
    #  use POSIX qw(tmpnam)
    my $result = qx($^X -c $file 2>err.tmp);

    open ERR, "<err.tmp" or return $!;
    local $/;
    my $err = <ERR>;
    close ERR;
    unlink "err.tmp";

    # one more test
    $self->{result}[0]++;

    # Did it work?
    if ( $err =~ /syntax OK/ ) {
        $self->{result}[1]++;
        push @{ $self->{result} }, "";
    }
    else {
        push @{ $self->{result} }, $err;
    }
}

=item $test->ioee( $in, $out, $err, $exit, time => $time, stdout => $limit, stderr => $limit );

Given C<$in>, the script should output C<$out> on STDOUT, C<$err> on
STDERR and return the exit code C<$exit>. If you don't care about any
of the tree outputs (stdout, stderr or exit code), just pass C<undef>.

You can pass further three limits to tune the test:

=over 4

=item o

A time limit for each test (default 30 seconds).

=item o

A data limit for stdout (default 1 megabyte).

=item o

A data limit for stderr (default 1 megabyte).

=back

B<WARNING!> This sub is a minimal workaround, and may deadlock on big
input sets, since we do not check via select if we can write.

=cut

sub ioee {
    my ( $self, $in, $out, $err, $exit ) = splice @_, 0, 5;

    use constant SELECT_TIMEOUT => 0.05;

    my $file = $self->{file} . ".pl";

    # Restrictions to apply
    my %restrict = 
      ( time   => 30,		# 30 Seconds
	stdout => 1000000,	# 1  Megabyte
	stderr => 1000000,	# 1  Megabyte
	@_
      );

    croak "Invalid parameters passed!"
      unless (scalar keys %restrict == 3);

    # Storage for data read
    my ($stdout, $stderr) = ("", "");


    # Use exceptions
    eval {
        # Start code under test
	local (*IN, *OUT, *ERR);
	my $pid  = open3(\*IN, \*OUT, \*ERR, "$^X $file");

	# Use select to monitor filehandles
	my $select = IO::Select->new;
	$select->add(\*OUT, \*ERR); # do not check \*IN.

	# Do writing.
	print IN $in;
	close IN;

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
	close OUT;
	close ERR;
    };

    # Handle exceptions (TODO)
    #if ($@) {
    #	die $@;
    #}

    # one more test.
    $self->{result}[0]++;
    my $success = 1;
    my $msg     = "";

    if ( $stdout ne $out ) {
	# Ooops, wrong output.
	$success = 0;
        $msg = "Oops, wrong output.\nExpected:\n--\n".$out."--\nGot:\n--\n".$stdout."--";

    } 

    if ( $stderr ne $err ) {
	# Ooops, wrong stderr.
	$success = 0;
        $msg = "Oops, wrong stderr.\nExpected:\n--\n".$err."--\nGot:\n--\n".$stderr."--";
    } 

    # Test is ok.
    $self->{result}[1] += $success;
    push @{ $self->{result} }, $msg;
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

    # one more test
    $self->{result}[0]++;

    # did it compile?
    $self->{result}[1]++ unless $@;
    push @{ $self->{result} }, $@;

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
    &{ $self->{sub} } (@_) if defined $self->{sub};
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
    $self->{result}[0]++;
    if ($ok) {
        $self->{result}[1]++;
        $msg = "";
    }
    push @{ $self->{result} }, $msg;
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

    $self->{result}[0]++;
    if ( index( $code, $s ) < $[ ) {
        $self->{result}[1]++;
        $msg = "";
    }
    push @{ $self->{result} }, $msg;
}

=item $test->not_match( $regex );

Test that the code in the entry doesn't match C<$regex>.

=cut

sub not_match {
    my ( $self, $regex ) = @_;

    my $msg  = "Oops, your code matched $regex.\n";
    my $code = $self->{code};
    $code =~ s/\A.*\n//m;    # Shebang line may contain anything.

    $self->{result}[0]++;
    if ( $code !~ /$regex/ ) {
        $self->{result}[1]++;
        $msg = "";
    }
    push @{ $self->{result} }, $msg;
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

=item Steffen Müller         E<lt>tsee@gmx.netE<gt>

=item Jonathan E. Paton      E<lt>jonathanpaton@yahoo.comE<gt>

=item Jérôme Quelin          E<lt>jerome.quelin@insalien.orgE<gt>

=item Eugène Van der Pijll   E<lt>E.C.vanderPijll@phys.uu.nlE<gt>

=back

=head1 COPYRIGHT

This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>, L<Games::Golf>, L<Games::Golf::Entry>.

=cut


