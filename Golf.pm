#
# $Id: Golf.pm,v 1.48 2002/05/31 23:26:56 book Exp $
#

package Games::Golf;

use 5.005;
use strict;
local $^W = 1; # Enable warnings the old way

use vars qw/ $VERSION $AUTOLOAD $subs /;
BEGIN {
    # add all registered autoloaded accessors here
    my @subs = map { ("set_$_", "get_$_") } split /\|/,
               $subs = 'version|pgas';
    $subs = join '|', @subs;
    use subs @subs;
}

$VERSION = '0.15';

# Modules we rely upon...
use Carp;
use Data::Dumper ();
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

=head2 Constructor

=over 4

=item new( $file )

Creates a new C<Games::Golf> object. You are to provide the name of a
configuration file that will describe the course (see L<"CONFIG FILE">
for details about this file).

=cut

sub new {

    # Create the object, and bless it.
    my $class = shift;
    my $file  = shift
      || croak "fatal: Not enough parameters for Games::Golf constructor";
    my $self = {
        file     => $file,
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

=head2 Accessors

=over 4

=item file()

The configuration file of the course.

=cut

sub file { shift->{file} }

=item hole_names()

Return the list of the course's holes names.

=cut

sub hole_names {
    my $self = shift;
    return keys %{ $self->{testers} };
}

=back

The following accessors are autoloaded.

=over 4

None yet.

=cut

sub AUTOLOAD {
    # we don't DESTROY
    return if $AUTOLOAD =~ /::DESTROY/;

    # fetch the attribute name
    $AUTOLOAD =~ /.*::(\w+)/;
    my $attr = $1;
    # must be one of the registered subs (compile once)
    if( $attr =~ /^(?:[gs]et)?(?:$subs)$/o ) {
        no strict 'refs';

        # get the attribute name
        $attr =~ s/^[sg]et_//;

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

=head2 Public methods

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
    $self->{entries}{$id} = $entry
        unless exists $self->{entries}{$id};

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

=item dump( $file )

Dump all entries in a single file.

=cut

sub dump {
    my ( $self, $file ) = @_;

    # Open file and dump.
    open DUMP, "> $file" or croak "fatal: can't open $file: $!";
    print DUMP Data::Dumper->Dump([ $self->{entries} ],
                                  [ 'Games::Golf::_entries' ]);
    print DUMP "\n1;\n"; # make sure the do() will return a true value
    close DUMP;
}

=item load( $path )

Read a file with all previously recorded entries. See the C<dump>
method. This initiates the cache mechanism.

=cut

sub load {
    my ( $self, $file ) = @_;

    # nothing to load
    return unless -e $file;

    # read in config files: system first, then user
    unless ( my $return = do $file) {
        croak "fatal: couldn't parse $file: $@" if $@;
        croak "fatal: couldn't do $file: $!"    unless defined $return;
        croak "fatal: couldn't run $file"       unless $return;
    }
    # the name is hardcoded by the dump method
    # and the use of do() coerces us into making _entries a package global
    $self->{entries} = $Games::Golf::_entries;
    undef $Games::Golf::_entries; # clean up after
}

=back

=head2 PRIVATE METHODS

=over 4

=item _parse_config_file()

Parse the config file, and fetch all attributes of the course. Create
the C<Games::Golf::TestSuite> objects for each of the holes.

=cut

sub _parse_config_file {
    my $self   = shift;
    my $config = {};

    open CFG, "< $self->{file}" or croak "Can't open $self->{file}: $!";

    # read the .glf file to extract configuration and hole data
    my ( $conf, $hole, $tiebreak, %code, %conf, %tiebreak );

    # many things can break here,
    # particularly if the pod contains =begin within =begin,
    # which pod doesn't support anyway.
    while (<CFG>) {

        # very important!
        last if /^__END__$/;

        # new configuration section
        /^=begin\s+(conf|hole|tiebreaker)\b(.*)?/ && do {
            if ( $1 eq 'hole' ) {
                $conf = 1;
                $hole = $2;
                $hole =~ s/^\s*|\s*$//g;           # trim variable name
                $hole =~ /^[-\w]+$/ or croak "fatal: bad hole name";
                $conf{$hole}->{name} = "$hole.pl"; # set a default
            }
            elsif ( $1 eq 'tiebreaker' ) {
                $tiebreak = $2;
                $tiebreak =~ s/^\s*|\s*$//g;       # trim variable name
                $tiebreak =~ /^[-\w]+$/ or croak "fatal: bad tiebreaker name";
                $tiebreak{$tiebreak} = '';         # prepare hash element
                $tiebreak{':default'} ||= $tiebreak;
            }
            else { $conf = 1 }
            next;
        };

        # end of configuration section
        # $hole remains set
        /^=end\s+(conf|hole|tiebreaker)/ && do {
            undef $conf;
            undef $tiebreak;
            next;
        };

        # use the data line
        # as configuration directive
        if ($conf) {
            next if /^\s*(#|$)/;    # ignore comments and blank lines
            /^\s*(\w+)\s*=\s*(.*?)\s*$/
              or croak "fatal: bad configuration directive in $self->{file} "
                     . "line $.:\n$_";
            $conf{ $hole || ':main' }->{ lc $1 } = $2;
            next;
        }

        # this is tiebreaker code
        $tiebreak{$tiebreak} .= $_, next if $tiebreak;

        # this is hole code
        $code{$hole} .= $_ if $hole;
    }

    close CFG;

    # Create a coderef for the defined tiebreakers
    foreach my $key ( keys %tiebreak ) {
        next if $key eq ':default'; # special case

        # evaluate code
        my $code_ref = eval 'sub {' . $tiebreak{ $key } . '}';

        if ( $@ ) { # an error occurred... croak
            croak <<HERE;
Error while evaluating tiebreaker: $@
The tiebreaker '$key' is broken:
$tiebreak{$key}
HERE
        }

        # tiebreaker is valid Perl code.
        $tiebreak{ $key } = $code_ref;
    }

    # the default default tiebreaker does nothing
    $tiebreak{':default'} = $tiebreak{$tiebreak{':default'}} || sub {};

    # now create the Games::Golf::TestSuite objects
    for my $hole ( keys %code ) {
        my $tester = $self->{testers}{$hole} =
          new Games::Golf::TestSuite( $code{$hole}, "$hole.pl" );

        # set the various defaults
        $conf{$hole}->{version} ||= $conf{':main'}->{version};
        $conf{$hole}->{tiebreaker} ||= ':default';
        $conf{$hole}->{tiebreaker} = $tiebreak{ $conf{$hole}->{tiebreaker} };

        # set the GGT attributes
        for my $key ( keys %{ $conf{$hole} } ) {
            my $accessor = "set_$key";
            $tester->$accessor( $conf{$hole}->{$key} );
        }
    }

    # and set the Games::Golf attributes the same way
    for my $key ( keys %{ $conf{':main'} } ) {
        my $accessor = "set_$key";
        $self->$accessor( $conf{':main'}->{$key} );
    }
}

1;

__END__

=head1 CONFIG FILE

Once the course is launched, the referees are to provide a file which
will describe the course.


=head1 ENVIRONMENT VARIABLES

!!FIXME!! Shouldn't environment variables be handled by the player/referee
scripts?

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

=item Amir Karger            E<lt>akarger@cpan.orgE<gt>

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

