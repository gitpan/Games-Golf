use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Games::Golf',
    'VERSION_FROM' => 'Golf.pm',
    'PREREQ_PM'    => {
        Carp           => 0.0,    # Minimums set to 5.005_03 vers
        File::Basename => 2.6,
        IO::File       => 1.08,
        IO::Select     => 1.14,
        IPC::Open3     => 1.0103,
        POSIX          => 1.03,
    },
    'EXE_FILES'    => [
        'scripts/golf',
        'scripts/referee',
    ],
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
