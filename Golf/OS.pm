package Games::Golf::OS;

require Exporter;
@ISA    = qw( Exporter );
@EXPORT = ();
@EXPORT_OK = qw( is_Windows is_Windows9x is_WindowsNT is_Unix os_name );
%EXPORT_TAGS = (
    functions => [ qw( is_Windows is_Windows9x is_WindowsNT is_Unix ) ],
    windows   => [ qw( is_Windows is_Windows9x is_WindowsNT ) ],
);

=head1 NAME

Games::Golf::OS - An Operating System detector for Games::Golf

=head1 SYNOPSIS

    # nothing is exported by default
    use Games::Golf::OS;
    print "Doing Windows!" if Games::Golf::OS::is_Windows();

    # but you can ask for it
    use Games::Golf::OS qw/ :functions /;
    print "We don't do no Windows" unless is_Windows();

=head1 DESCRIPTION

Games::Golf has a complicated way to capture output and errput,
which depends on the operating system it's running on.
This module provide several functions that do the boring tests for us.

There are two tags: C<:functions> exports all functions except os_name(),
while C<:windows> only exports the three functions related to the Microsoft
Windows operating system.

=cut

# the main variable!
my $os;

# The OS detection process...

# Is this Windows?
if ( $^O eq 'MSWin32' ) {
    $os = 'Windows::unknown';

    # from Get Even Golf Game
    # http://archive.develooper.com/fwp%40perl.org/msg01203.html
    $os = 'Windows::NT' if Win32::IsWinNT();
    $os = 'Windows::9x' if Win32::IsWin95();
    # http://aspn.activestate.com/ASPN/Reference/Products/ActivePerl/lib/Win32.html
}

# or some Unix variant?
elsif (
    $^O =~ / aix      | bsdos  | dec_osf | dgux    | dynixptx | freebsd
           | hpux     | irix   | linux   | machten | next     | openbsd
           | rhapsody | sco_sv | solaris | sunos   | svr4     | unicos
           | unicosmk /x) {
    $os = "Unix::$^O";
}

# or something else we don't support (yet)
else { $os = $^O; }

=head2 AVAILABLE METHODS

Several boolean methods are avalaible. The names should be
self-explanatory. All the methods return C<""> for false.
Some specific details can be returned for true.

=over 4

=item is_Windows()

Return the variant (C<"9x"> or C<"NT">) if the system is a Microsoft
Windows variant.

=cut

sub is_Windows {
    return is_Windows9x() || is_WindowsNT();
}

=item is_Windows9x()

Return true (C<"9x">) is we are running under some Windows 95 subsystem.
(Windows 95, Windows 98.)

=cut

sub is_Windows9x() { $os eq 'Windows::9x' ? '9x' : ''; }

=item is_WindowsNT()

Return true (C<"NT">) is we are running under some Windows NT subsystem.
(Windows NT, Windows 2000, Windows XP.)

=cut

sub is_WindowsNT() { $os eq 'Windows::NT' ? 'NT' : ''; }

=item is_Unix()

Return the Unix variant if the system is some flavour of Unix.
(We don't do "vanilla" Unix, though.)

=cut

sub is_Unix {
    $os =~ /^Unix::(.*)/;
    return $1 || "";
}

=item os_name()

For those who really want it, you can also get the string used internally
to store the OS representation. You have to explicitely ask for it to
be exported.

=cut

sub os_name { $os }

1;

__END__

=back

=head1 AUTHORS

Philippe 'BooK' Bruhat.

See Games::Golf or the included AUTHORS file for the complete list of
authors.

=head1 SEE ALSO

perl(1), perlport(1), Games::Golf::TestSuite.

=cut

