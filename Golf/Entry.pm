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
# $Id: Entry.pm,v 1.13 2002/02/24 14:22:22 book Exp $
#
package Games::Golf::Entry;

use strict;
use vars qw/ $AUTOLOAD $VERSION $subs /;

BEGIN {
    # add all registered accessors here
    my @subs = split /\|/,
               $subs = 'author|email|nick|hole|date|code|result|id';
    use subs @subs;
}

# Modules we rely upon.
use Carp;

# Variables of the module.
local $^W = 1;    # use warnings for perl < 5.6
$VERSION = '0.08';

use subs qw/ author email nick hole date code file id/;

=head1 NAME

Game::Golf::Entry - Single solution for a golf hole.

=head1 SYNOPSIS

  use Game::Golf;

  my $entry = new Game::Golf::Entry ( "hole.pl" );

  $entry->test;

  $entry->print_report;

  $entry->test_ok or die;

=head1 DESCRIPTION

Internal object to be used by C<Game::Golf>. Each solution represents 
a single hole. 

=head2 CONSTRUCTOR

=over 4

=item new( "author", "hole_name", "/path/to/solution/file" )

Creates a new C<Game::Golf::Entry> object. You should pass the path to
the file that holds the solution.

!!FIXME!! We should pass the hole name in order to know which test
suite to apply.

!!FIXME!! Should we pass arguments as an array or as a hash?

!!FIXME!! Maybe we could create another constructor that will accept
directly the code to test? Don't sure this is a good idea.

=back

=cut

sub new {

    # Create the object, and bless it.
    my $class = shift;
    my $self  = {
        author => "",
        email  => "",
        nick   => "",
        date   => "",
        hole   => "",
        code   => "",
        score  => undef,
        result => "",
        tests  => [],
        status => undef,
        @_
    };
    bless $self, $class;

    # !!FIXME!! Should we check that user supplied all infos?

    # Return the new object.
    return $self;
}

=head2 ACCESSORS

All the accessors are autoloaded.

=over 4

=item author()         Full name of the author.

=item email()          Author's nickname.

=item nick()           Author's nickname.

=item hole()           The name of the hole this solution solves.

=item date()           Date of the entry.

=item code()           The entry's code.

=item result()         The entry's test result.

=item file()           Filename of the entry.

=item id()             MD5 sum of the file, to make caching easier.

=back

=cut

# Philippe takes responsability for this one ;)
sub AUTOLOAD {
    # we don't DESTROY
    return if $AUTOLOAD =~ /::DESTROY/;

    # fetch the attribute name
    $AUTOLOAD =~ /.*::(\w+)/;
    my $attr = $1;
    # must be one of the registered subs (compile once)
    if( $attr =~ /$subs/o ) {
        no strict 'refs';

        # create the method (but don't pollute other namespaces)
        *{$AUTOLOAD} = sub {
            my $self = shift;
            @_ ? $self->{$attr} = shift: $self->{$attr};
        };

        # now do it
        goto &{$AUTOLOAD};
    }
    # should we really die here?
    croak "Undefined method $AUTOLOAD";
}

=head2 METHODS

=over 4

=item test()

Run the test suite on this entry.

=cut

=item test_ok()

Return true if entry passed the test suite.

!!FIXME!! A simple true/false value, or maybe a percentage if we're
playing with Test::Harness?

=item print_report()

Outputs result of the tests.

!!FIXME!! This means whe should cache also the result of tests?

=back

=cut

=item test_one

=cut

sub test_one {
    my $self = shift;
    my %opt  = (
        infile   => undef,
        stdout   => "",
        stderr   => "",
        argv     => undef,
        exitcode => undef,
        @_
    );
    my $codetmp = 'code.tmp';
    my $intmp   = 'in.tmp';
    my $errtmp  = 'err.tmp';
    _build_file( $codetmp, $self->{code} );
    my $cmd = "$^X $codetmp";
    if ( defined $opt{infile} ) {
        _build_file( $intmp, $opt{infile} );
        $cmd .= " $intmp";
    }
    $cmd .= " $opt{argv}" if defined $opt{argv};
    $cmd .= " 2>$errtmp";
    my $output = `$cmd`;
    my $ec     = $? >> 8;
    my $OK     = 1;
    if ( defined $opt{exitcode} and $opt{exitcode} != $ec ) {
        print "Exit code expected: $opt{exitcode}\nGot: $ec\n";
        $OK = 0;
    }
    if ( defined $opt{stdout} and $opt{stdout} ne $output ) {
        print "stdout expected:\n$opt{stdout}\nGot:\n$output\n";
        $OK = 0;
    }
    if ( defined $opt{stderr} ) {
        my $err = '';
        if ( -s $errtmp ) {
            local (*FF);
            local $/ = undef;
            open FF, $errtmp or die "error: open $errtmp: $!";
            $err = <FF>;
        }
        if ( $opt{stderr} ne $err ) {
            print "stderr expected:\n$opt{stderr}\nGot:\n$err\n";
            $OK = 0;
        }
    }
    return $OK;
}

=item score()

Compute the this Entry's score.

=cut

sub score {
    my $self = shift;
    defined $self->{score} and return $self->{score};

    my $code = $self->{code};
    $code =~ s/\n$//;           # Free last newline.
    $code =~ s/^#!\S*perl//;    # Shebang.
    $self->{score} = length($code) - 1;    # Free first newline.
}

#------------------------------------#
#          Private methods.          #
#------------------------------------#

sub _build_file {
    my ( $fname, $data ) = @_;
    local (*FF);
    open( FF, '>' . $fname ) or croak "Could not open '$fname': $!";
    print FF $data;
    close(FF);
}

1;
__END__

=head1 BUGS

Please report all bugs to:

http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-Golf

=head1 TODO

Lots of stuff.

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

L<perl>, L<Game::Golf>.

=cut

