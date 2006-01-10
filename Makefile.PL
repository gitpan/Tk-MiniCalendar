use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tk::MiniCalendar',
    VERSION_FROM      => 'lib/Tk/MiniCalendar.pm', # finds $VERSION
    dist => { POSTOP => ('@echo "************  ATTENTION: are README, Changes und MANIFEST ok ? *******"') },
    PREREQ_PM         => {Tk::XPMs => 1.03,
                          Date::Calc => 5.0,
                          Tk => '0',
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Tk/MiniCalendar.pm', # retrieve abstract from module
       AUTHOR         => 'Lorenz Domke <lorenz.domke\@gmx.de>') : ()),
);
