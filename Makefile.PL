use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'         => 'Games::Golf',
    'VERSION_FROM' => 'Golf.pm',
    'PREREQ_PM'    => {},
    'EXE_FILES'    => [ 'scripts/golf' ],
    ( $] >= 5.005    # Add these new keywords supported since 5.005
    ? (
          ABSTRACT_FROM => 'Golf.pm',    # retrieve abstract from module
          AUTHOR        => join ', ',
          'Philippe "BooK" Bruhat <book@cpan.org>',
          'Dave Hoover <dave@redsquirreldesign.com>',
          'Steffen Muller <games-golf@steffen-mueller.net>',
          'Jonathan E. Paton <jonathanpaton@yahoo.com>',
          'Jerome Quelin <jquelin@cpan.org>',
          'Eugene Van der Pijll <E.C.vanderPijll@phys.uu.nl>'
      )
    : () ),
);
