#-*- perl -*-
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# $Id: Entry.pm,v 1.36 2002/05/13 15:07:51 smueller Exp $
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
               $subs = 'author|email|hole|date|code|result|id';
    use subs @subs;
}

# declare a class attribute, which is defined later
my %tiebreak;

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
        result      => [ 0, 0 ],
        tests       => [],
        status      => undef,
        score       => undef,
        tiebreaker  => { },
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
    my ($sec,$min,$hour,$mday,$mon,$year) = localtime( $self->date );
    $mon++; $year += 1900;
    return sprint( "%04d.%02d.%02d %02d:%02d:%02d",
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

=item id()

MD5 sum of the file, to make caching easier.

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


=item tiebreak( $tie, [ $tie2 , ... ] );

Compute and return this entry tie-breaking scores.

This method is meant to be used as an accessor.

If C<$tie> is a string, it's used to look up one of the predefined
tie-breaking values. If it's a coderef, the given subroutine is
used to compute the tie-breaking value. This value is I<not> cached.

Examples of use:

 # return the date tie-breaker
 $tie = $entry->tiebreak( "date" );

 # yet another way to break ties
 $tie = $entry->tiebreak( sub { rand } );

 # return both in a hash
 %tie = $entry->tiebreak( "date",  sub { rand } );

 # all predefined tie-breaking values
 %tie = $entry->tiebreak;

Several tie-breaking routines are predefined. They are meant to be used
as the decimal part of a score. So they should be such that the lower
C<$entry-E<gt>score() + $entry-E<gt>tiebreak()>, the better the overall
score is.

=cut

sub tiebreak {
    my $self = shift;

    # compute all values
    if ( not keys %{ $self->{tiebreaker} } ) {
        %{ $self->{tiebreaker} } =
          map { ( $_, $tiebreak{$_}->($self) ) } keys %tiebreak;
    }

    # what did they ask for?
    if ( @_ == 0 ) { return %{ $self->{tiebreaker} } }
    my %ties = map {
        my $tiebreak = $self->{tiebreaker}{$_};
        if ( ref $_ eq 'CODE' ) {
            $tiebreak = $_->($self);
            # warning: this relies on $_ being an alias
            $_ = 'userdefined';    # !!FIXME!! nothing better?
        }
        ( $_, $tiebreak );
    } @_;

    # return either a value, or a hash
    return @_ == 1 ? $ties{ $_[0] } : %ties;
}

=pod

The predefined tie-breaking values are:

=over 4

=item date

The sooner the code is submitted, the better.
This value is simply computed as YYYYMMDDhhmmss, or in POSIX strftime()
parlance: C<"%Y%m%d%H%M%S">.

=item weird

The bigger the percentage of "weird characters", the better.
Weird characters are defined as C<[^\w\s]>.

!!FIXME!! 1 is an invalid value! It'll increase the score by one, if
we use this tiebreaker in an addition. My proposition is to compute
the percentage as the number of non weird char divied by score + 1.

=back

=cut

%tiebreak = (
    # !!FIXME!! to be defined!
    date => sub {},

    weird => sub {
        my $entry = shift;
        my $code  = $entry->code;
        # !!FIXME!! Some code is duplicated in score()
        # we might create a sub like morphcode() to handle these
        $code =~ s/\r\n|\n\r/\n/g;         # Handle newlines the smart way.
        $code =~ s/\n+$//;                 # Free last newlines.
        $code =~ s{^#![-\w/.]+?perl}{};    # Shebang.
        my $score = length($code) - 1;     # Free first newline.
        $code =~ s/[^\w\s]//g;             # Strip weird chars.
        $score = ( length($code) - 1 ) / $score;
        return $score;
    }

);

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

