#
# $Id: Golf.pm,v 1.38 2002/05/13 14:03:57 smueller Exp $
#

package Games::Golf;

use 5.005;
use strict;
local $^W = 1; # Enable warnings the old way

use vars qw/ $VERSION $AUTOLOAD $subs /;
BEGIN {
    # add all registered accessors here
    my @subs = split /\|/, $subs = 'file';
    use subs @subs;
}

$VERSION = '0.14';

# Modules we rely upon...
use Carp;
use Games::Golf::Entry;
use Games::Golf::TestSuite;

=head1 NAME

Games::Golf - Utilities to handle Perl Golf courses

=head1 SYNOPSIS

  use Games::Golf;
  my $golf = new Games::Golf( "tpr.glf" ); 

  $golf->read( "entries.dat" );

  $golf->test;

  $golf->dump( "entries.dat" );

=head1 DESCRIPTION

The game of Perl golf is becoming increasingly popular. Holes
frequently appear on Perl Monks, the Perl Review has an ongoing Perl
Golf column and a monthly tournament, the Fun with Perl mailing-list
has run several very successful courses in the last few months, with
great success. So much success, in fact, that the golf@perl.org
mailing-list has been resurrected.

Until now, judges have had to write extensive test programs to check
and score the players' entries along with compiling the leaderboard by
hand. On the other hand, golfers have to check their entries, and
submit their entries themselves.

This module aims at facilitating the administration of Perl golf
courses by writing a simple configuration file for the referees, and
providing scripts for both the referee and the player side.

The included golfer script will test a player's individual entries
(doing all the hard scoring and testing), as well as submitting the
entries.

The C<Games::Golf> object will handle a list of C<Games::Golf::Entry> 
objects, as well as a list of C<Games::Golf::TestSuite.pm> objects.

=head2 CONSTRUCTOR

=over 4

=item new( $file )

Creates a new C<Games::Golf> object. You are to provide the name of a
configuration file that will describe the course (see L<"CONFIG FILE">
for details about this file).

=cut

sub new {
    # Create the object, and bless it.
    my $class = shift;
    my $file  = shift || croak "Not enough parameters";
    my $self     = 
      { file     => $file,
        entries  => {},
        deadline => undef,
        referees => {},
        testers  => {}
      };
    bless $self, $class;

    $self->_parse_config_file();

    # Return the new object.
    return $self;
}

=back

=head2 ACCESSORS

=over 4

=item hole_names(  )

Return the names of the holes of the course.

=cut

sub hole_names {
    my $self = shift;
    return keys %{ $self->{testers} };
}

=back

The following accessors are autoloaded.

=over 4

=item file(  )

The configuration file of the course.

=cut
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

=back

=head2 PUBLIC METHODS

=over 4

=item FIXME_extract( "/path/to/mbox", ... )

Extracts solutions from a unix-style mbox. A cache mechanism allows
the C<Games::Golf> object not to extract already extracted entries.

=cut 

sub FIXME_extract {
    my $self = shift;
    my @new;

    # Non-standard modules we rely on...
    eval "require Mail::Util;";
    croak "Module Mail::Util required"  if $@;
    eval "require Date::Manip;";
    croak "Module Date::Manip required" if $@;
    import Mail::Util qw(read_mbox);    # !!FIXME!! non-unix mbox formats? OE?
    import Date::Manip qw(UnixDate);

    # Format deadline.
    defined $self->{deadline}
      and $self->{deadline} = UnixDate( $self->{deadline}, "%Y.%m.%d.%H.%M.%S" );

    foreach my $mbox (@_) {

        # Prepare strings to be eval'd.
        my $code_end = '$line =~ /^__END__/o and undef $extr_to;';
#          my $code_beg;
#          foreach my $hole ( @{ $self->{holes} } ) {
#              $code_beg .= '$line =~ /^' . $hole
#                . '/o and $extr_to = "' . $hole
#                . '.".++$id{' . $hole . '};';
#          }

        # Read mbox.
        my @mails = read_mbox($mbox);

        foreach my $mail (@mails) {
            my ( $from,    $date );
            my ( $name,    $nick, $category );
            my ( $extr_to, %id, %scripts );

            # Merge headers-to-be-continued.
            my $last_line_header;
            foreach my $i ( 0..$#$mail ) {
                $last_line_header = $i, last
                  if $mail->[$i] =~ /^$/;
            }
            foreach my $i ( 0..$last_line_header ) {
                $mail->[$i] =~ s/^\s+/ /  # remove \n of $mail->[$i-1]
                  and substr $mail->[$i-1], -1, 1, $mail->[$i];
            }

            # Parse mail.
            foreach my $line ( @$mail ) {
                chomp($line);

                # Extract all that we can.
                $line =~ /^From:.*?<?(\S+@[^>]+)/o   and $from     = $1;
                $line =~ /^Received:.*;([^;]+)/o     and $date     = $1;
                $line =~ /^Golfer: (.*)/o            and $name     = $1;
                $line =~ /^Hole: (.*)/o              and $extr_to  = $1;
#                  $line =~ /^X-Golf-Name:\s*(.*)/o     and $name     = $1;
#                  $line =~ /^X-Golf-Nick:\s*(.*)/o     and $nick     = $1;
#                  $line =~ /^X-Golf-Category:\s*(.*)/o and $category = $1;
                eval $code_end;    # check end of script.
                defined $extr_to and $scripts{$extr_to} .= "$line\n";
#                  eval $code_beg;    # check beginning of script.

            }

            # pgas format.
            foreach ( values %scripts ) {
                # Black magic on alias.
                s/\A.*__BEGIN__\n//s;
            }

            # Check deadline.
            $date = UnixDate( $date, "%Y.%m.%d.%H.%M.%S" );
            defined $self->{deadline} and $date gt $self->{deadline} and next;

            # Fill in the Games::Golf object.
            foreach my $key ( keys %scripts ) {
                # Extract hole name.
#                my ( $hole, $ver ) = $key =~ /^(.*)\.(\d+)$/;
                my $hole = $key;

                # Default values if not supplied.
                $name or $name = $from;
                $nick or $nick = $name;

                my $id = $nick . $scripts{$key};        # Compute unique id.
                exists $self->{entries}{$id} and next;  # Uh, already submitted.

                # Create new entry and store it
                # in the Games::Golf object, and in the @new array
                push @new, $self->{entries}{$id} = Games::Golf::Entry->new(
                    author => $name,
                    email  => $from,
                    nick   => $nick,
                    date   => $date,
                    hole   => $hole,
                    code   => $scripts{$key}
                );

            }
        }
    }
    return @new;
}

=item add( $entry )

Store an entry in the C<Games::Golf> object. The paramater is a
C<Games::Golf::Entry> object.

Return the entry (either the new one, or the old one if the same entry
was already in the cache).

=cut

sub add {
    my ($self, $entry) = @_;

    my $id = $entry->id();
    $self->{entries}{$id} = $entry unless
      exists $self->{entries}{$id};
    return $self->{entries}{$id};
}

=item test( [ @holes ] )

Tests the entries stored in the object. A cache mechanism (implemented
in C<Games::Golf::TestSuite::run()>) allows the C<Games::Golf> object not to
re-check already tested entries.

You can pass a list of holes to test, and the object will test
the solutions of these holes only.

If no hole is given, then all holes are tested.

=cut

sub test {
    my $self  = shift;
    my @holes = @_ ? @_ : $self->hole_names;
    foreach my $hole ( @holes ) {
        my @entries = grep { $_->hole eq $hole } values %{ $self->{entries} };
        $self->{testers}{$hole}->run( @entries );
    }
}

=item dump( $path )

Dump all entries in a single file.

=cut

sub dump {
    my ( $self, $path ) = @_;
    $path or return;

    # Module we rely upon.
    eval { require Data::Dumper; };
    if ( $@ ) {
        carp "Module Data::Dumper required";
        return;
    }
    import  Data::Dumper qw(Dumper);

    # Open file and dump.
    open DUMP, ">$path" or croak $!;
    print DUMP Dumper( $self->{entries} );
    close DUMP;
}

=item load( $path )

Read a file with all previously recorded entries. See the C<dump>
method. This initiates the cache mechanism.

=cut

sub load {
    my ( $self, $path ) = @_;
    $self->{entries} = do $path or croak $!;
}

=back

=head2 PRIVATE METHODS

=over 4

=item _parse_config_file(  )

Parse the config file, and fetch all attributes of the course. Create
the testers for each of the holes.

=cut

sub _parse_config_file {
    my $self = shift;

    open CFG, "<$self->file" or croak "Can't open config file: $!";
    my $content;
    {
        local $/;
        $content = <CFG>;
    }
    close CFG;

    my $hole = ( $self->file =~ m!([^/]+)\.glf\z! );

    # For now, the config file contains only the test-code for only
    # one hole (multihole will be handled later).  Note that we
    # prepare for multihole by using an anonymous hash, but the only
    # value accepted by now is "hole".
    $self->{testers}{$hole} = new Games::Golf::TestSuite( $content, "$hole.pl" );
}

1;

__END__

=head1 CONFIG FILE

Once the course is launched, the referees are to provide a file which
will describe the course.


=head1 ENVIRONMENT VARIABLES

=head2 PERL_GOLF_NICK

Specifies the name to be printed on the leaderboard instead of the
mail adress of the golfer.

=head2 PERL_GOLF_CATEGORY

This one can be set to indicate whether golfer is experienced
(default, "veteran") or a newcomer ("beginner").

=head1 FILES

=head2 tests/*.t 

The test suite for a golf course.

!!FIXME!! "tests/*" or "t/*"? t/* will already be taken by the 
module...

=head2 extracted/*

The directory where to store extracted entries.

!!FIXME!! Should we allow an environment variable to overwrite this?

=head1 DEPENDENCIES

=over 4

=item *

C<Date::Manip> to handle dates the smart way.

=item *

C<Data::Dumper> to easily dump and fetch our entries.

=item *

C<MD5> to implement our cache mechanism.

=back

=head1 TODO

Lots of stuff.

=head1 BUGS

Please report all bugs to:

http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-Golf

=head1 AUTHORS

=over 4

=item Philippe 'BooK' Bruhat E<lt>book@cpan.orgE<gt>

=item Dave Hoover            E<lt>dave@redsquirreldesign.comE<gt>

=item Steffen Müller         E<lt>games-golf@steffen-mueller.netE<gt>

=item Jonathan E. Paton      E<lt>jonathanpaton@yahoo.comE<gt>

=item Jérôme Quelin          E<lt>jquelin@cpan.orgE<gt>

=item Eugène Van der Pijll   E<lt>E.C.vanderPijll@phys.uu.nlE<gt>

=back

=head1 COPYRIGHT

This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>, L<Games::Golf::Entry>.

=cut

