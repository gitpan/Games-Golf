#
# Copyright (c) 2002
#          Philippe 'BooK' Bruhat <book@cpan.org>
#          Dave Hoover            <dave@redsquirreldesign.com>
#          Steffen Muller         <games-golf@steffen-mueller.net>
#          Jonathan E. Paton      <jonathanpaton@yahoo.com>
#          Jerome Quelin          <jquelin@cpan.org>
#          Eugene Van der Pijll   <E.C.vanderPijll@phys.uu.nl>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# $Id: Golf.pm,v 1.23 2002/03/09 11:47:18 jep Exp $
#

package Games::Golf;

use 5.005;
use strict;
use vars qw/$VERSION/;

# Modules we rely upon.
use Carp;
use Games::Golf::Entry;

# Variables of the module. blah
local $^W = 1;    # use warnings for perl < 5.6
$VERSION = '0.12';

=head1 NAME

Games::Golf - Utilities to administer Perl Golf courses

=head1 SYNOPSIS

  use Games::Golf;
  my $golf = new Games::Golf ( referee      => "Bob the Referee",
                              referee_mail => 'bob@referee.org'
                              holes        => [ qw( name1 name2 ) ],
                              deadline     => "2002/02/20",
                              );

  $golf->read( "entries.dat" );

  $golf->extract( "mbox" );

  $golf->test;

  $golf->dump( "entries.dat" );

  $golf->print_report;

  $golf->mail_report( 'fwp@perl.org' );


  Or, interactive:

  perl -MGames::Golf -e shell


=head1 DESCRIPTION

The game of Perl golf is becoming increasingly popular. Holes frequently
appear on Perl Monks, the Perl Review has an ongoing Perl Golf colunm,
and the Fun with Perl mailing-list has run several very successful 
courses in
the last few months, with great success.

Until now, judges have had to write extensive test programs to
check and score the players' entries along with compiling the
leaderboard by hand.

This module aims at facilitating the administration of Perl golf courses
by writing a simple configuration file and writing the test programs
as .t files.

The included scripts will test a player's individual entries, doing all
the hard scoring and testing for the judge. Methods to compute statistics
and leaderboards are also provided.

The C<Games::Golf> object will handle a list of C<Games::Golf::Entry> 
objects.

=head2 CONSTRUCTOR

=over 4

=item new( [ARGS] )

Creates a new C<Games::Golf> object. Parameters are:

  referee       Name of the referee.
  referee_mail  Mail of the referee (where solutions will be sent).
  deadline      Closing date of the game. Any format welcome.
  holes         Array ref to the names of the holes.

=back

=cut

sub new {

    # Create the object, and bless it.
    my $class = shift;
    my $self  = {
        entries     => {},
        holes       => [],
        deadline    => undef,
        referees    => [],
        @_
    };
    bless $self, $class;

    # Return the new object.
    return $self;
}

=head2 METHODS

=over 4

=item extract( "/path/to/mbox", ... )

Extracts solutions from a unix-style mbox. A cache mechanism allows
the C<Golf::Game> object not to extract already extracted entries.

=cut 

sub extract {
    my $self = shift;

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
        my $code_beg;
        foreach my $hole ( @{ $self->{holes} } ) {
            $code_beg .= '$line =~ /^' . $hole
              . '/o and $extr_to = "' . $hole
              . '.".++$id{' . $hole . '};';
        }

        # Read mbox.
        my @mails = read_mbox($mbox);

        foreach my $mail (@mails) {
            my ( $from,    $date );
            my ( $name,    $nick, $category );
            my ( $extr_to, %id, %scripts );

            # Merge headers-to-be-continued.
            my $seen;
            foreach my $i (reverse 0..$#$mail) {
                $mail->[$i] =~ /^$/ and $seen++;
                next unless $seen;
                $mail->[$i] =~ s/^\s+/ /  # remove \n of $mail->[$i-1]
                  and substr $mail->[$i-1], -1, 1, $mail->[$i];
            }


            # Parse mail.
            foreach my $line ( @$mail ) {
                chomp($line);

                # Extract all that we can.
                $line =~ /^From:.*?<?(\S+@[^>]+)/o   and $from     = $1;
                $line =~ /^Received:.*;([^;]+)/o     and $date     = $1;
                $line =~ /^X-Golf-Name:\s*(.*)/o     and $name     = $1;
                $line =~ /^X-Golf-Nick:\s*(.*)/o     and $nick     = $1;
                $line =~ /^X-Golf-Category:\s*(.*)/o and $category = $1;
                eval $code_end;    # check end of script.
                defined $extr_to and $scripts{$extr_to} .= "$line\n";
                eval $code_beg;    # check beginning of script.

            }

            # Check deadline.
            $date = UnixDate( $date, "%Y.%m.%d.%H.%M.%S" );
            defined $self->{deadline} and $date gt $self->{deadline} and next;

            # Fill in the Games::Golf object.
            foreach my $key ( keys %scripts ) {
                # Extract hole name.
                my ( $hole, $ver ) = $key =~ /^(.*)\.(\d+)$/;

                # Default values if not supplied.
                $name or $name = $from;
                $nick or $nick = $name;
                $date = UnixDate( $date, "%s" );

                my $id = $nick . $scripts{$key};        # Compute unique id.
                exists $self->{entries}{$id} and next;  # Uh, already submitted.

                # Create new entry and store it.
                $self->{entries}{$id} = Games::Golf::Entry->new(
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
}

=item test()

Tests entries of the game. A cache mechanism allows the Golf::Game
object not to check already tested entries.

!!FIXME!! We must now investigate further on the format of the test
suite. And have an example of such a test.

=cut

# sub test {}

=item dump( "/path/to/data" )

Dumps all entries in a single file.

Dies if there's a problem.

=cut

sub dump {
    my ( $self, $path ) = @_;
    $path or return;

    # Module we rely upon.
    require Data::Dumper;
    import Data::Dumper qw(Dumper);

    # Open file and dump.
    open DUMP, ">$path" or croak $!;
    print DUMP Dumper( $self->{entries} );
    close DUMP;
}

=item load( "/path/to/data" )

Reads a file with all previously recorded entries. See the C<dump>
method. This initiates the cache mechanism.

Dies if there's a problem.

=cut

sub load {
    my ( $self, $path ) = @_;
    $path or return;
    $self->{entries} = do $path;
}

=item print_report( [*FH] )

Prints the current leaderboard on STDOUT. If C<*FH> is supplied, use
this filehandle instead.

=cut

# sub print_report {}

=item mail_report( 'mail@adress.com', ... )

Mails the leaderboard to the specified adresses.

=cut

# sub mail_report {}

=item shell

Interactive play for both a golfer and the arbiter.

=back

=cut

# sub shel {}

1;
__END__

=head1 ENVIRONMENT VARIABLES

=head2 PERL_GOLF_SMTP_SERVER

This variable can be set to indicate which server is to be used to
send solutions or report.

!!FIXME!! What if the user wants to use a sendmail-based solution?

=head2 PERL_GOLF_NICK

Specifies the name to be printed on the leaderboard instead of the
mail adress of the golfer.

=head2 PERL_GOLF_CATEGORY

This one can be set to indicate if golfer is experienced (default,
"veteran") or a newcomer that would set it to "beginner".

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

