#-*- perl -*-
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# $Id: Entry.pm,v 1.40 2002/06/01 00:16:07 book Exp $
#
package Games::Golf::Entry;

use 5.005;
use strict;
local $^W = 1; # Enable warnings the old way

use Carp;

use vars qw/ $AUTOLOAD $subs /;

BEGIN {
    # add all registered accessors here
    my @subs = split /\|/,
               $subs = 'author|email|hole|date|code|result|version';
    use subs @subs;
}

=head1 NAME

Games::Golf::Entry - Single solution for a golf hole.

=head1 SYNOPSIS

  use Games::Golf;

  my $entry = new Games::Golf::Entry ( "hole.pl" );

  $entry->test;

  $entry->print_report;

  $entry->test_ok or die;

=head1 DESCRIPTION

Internal object to be used by C<Games::Golf>. Each solution represents 
a single hole. 

=head2 CONSTRUCTOR

=over 4

=item new( "author", "hole_name", "/path/to/solution/file" )

Creates a new C<Games::Golf::Entry> object. You should pass the path to
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
        author      => "",
        email       => "",
        date        => "",
        hole        => "",
        code        => "",
        version     => "",
        result      => [ 0, 0 ],
        tests       => [],
        status      => undef,
        score       => undef,
        @_
    };
    bless $self, $class;

    # !!FIXME!! Should we check that user supplied all infos?

    # Return the new object.
    return $self;
}

=head2 ACCESSORS

=over 4

=item id()

Return a unique id of the current entry.

=cut

sub id {
    my $self = shift;
    return $self->author . $self->code;
}

=item date_string()

Return the date in a human-readable format: yyyy.mm.dd hh::mm::ss

=cut

sub date_string {
    my $self = shift;
    return "" unless $self->date;

    my ($sec,$min,$hour,$mday,$mon,$year) = localtime( $self->date );
    $mon++; $year += 1900;
    return sprintf( "%04d.%02d.%02d %02d:%02d:%02d",
                    $year, $mon, $mday, $hour, $min, $sec );
}

=back

All the following accessors are autoloaded.

=over 4

=item author()

Full name of the author.

=item email()

Author's email address.

=item hole()

The name of the hole this solution solves.

=item date()

Date of the entry.

=item code()

The entry's code.

=item result()

The entry's test result. This is updated by the C<ok()> method, which should
only be used by the C<check()> method of C<Games::Golf::TestSuite> (do I make
myself clear?).

This structure is an array reference. The first parameter is the total
number of tests taken. The second parameters is the number of tests passed.
The rest of the array is the list of errors messages. C<""> means the test
passed. For example:

 $result = [
     5,  # total number of tests taken
     3,  # number of tests passed
     "", # ok 1
     "", # ok 2
     "expected:\n--\n3--\ngot:\n--\n4--\n" # not ok 3
     "", # ok 4
 ];

=item file()

Filename of the entry.

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

=item score()

Compute and return this Entry's score.

=cut

sub score {
    my $self = shift;
    defined $self->{score} and return $self->{score};

    my $code = $self->{code};
    $code =~ s/\n$//;                  # Free last newline.
    $code =~ s/^#!\S*perl//;     # Shebang.
    $self->{score} = length($code) - 1;    # Free first newline.
}

=item ok( $status, $msg )

B<WARNING:> This method should only be used in the C<Games::Golf::TestSuite>
object.

Updates the C<result> attribute of the C<Games::Golf::Entry> object.

If the test passed, C<$status> should be true (and the message stored will
be empty).

If the test failed, C<$status> should be false, and a message
should be given. If no message is given, C<ok()> will store a default
message in C<result>.  This means that you can be sure that if a message
in C<result> is true, then the test failed.

=cut

sub ok {
    my ( $self, $ok, $msg ) = @_;
    $msg ||= "Test failed with no message.";

    # update the counters
    $self->{result}[0]++;
    if( $ok ) {
        $self->{result}[1]++;
        $msg = "";
    }

    # don't forget the message
    push @{ $self->{result} }, $msg;
}

=back

=cut

1;

__END__

=head1 BUGS

Please report all bugs to:

http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-Golf

=head1 TODO

Lots of stuff.

=head1 AUTHORS

See AUTHORS file for the list of authors.

=head1 COPYRIGHT

This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>, L<Games::Golf>.

=cut

