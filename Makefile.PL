use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
use lib qw( ../blib/lib lib );
use Apache::Test;

use Apache::TestMM qw( test clean ); # enable 'make test'
use Apache::TestRun;
use Apache::TestTrace;
use Apache::TestReport;
use Apache::TestConfig ();

# Prerequisites:
my %require = (
  'Apache::Test'          => "",
  'Cwd' =>                => "",
  'CGI::Apache2::Wrapper' => 0.21,
  'XML::Simple' =>        => "",
  'Devel::StackTrace'     => "",
  'Test::More'            => "",
  'HTTP::Date'            => 1.47,
  'DBI'                   => 1.50,
  'Digest::MD5'           => "",
  'Apache2::Const'        => 2.000002,
  'DBD::SQLite'           => 1.13,
  'Storable'              => "",
  'Mail::Sendmail'        => "",
  'Time::HiRes'           => "",
);
my @scripts = qw( t/TEST );

# Accept configuration from the command line:
Apache::TestMM::filter_args();
Apache::TestMM::generate_script('t/TEST');

WriteMakefile(
  NAME              => 'Apache2::ASP',
  VERSION_FROM      => 'lib/Apache2/ASP.pm', # finds $VERSION
  PREREQ_PM         => \%require,
  dist => {
    PREOP => 'pod2text lib/Apache2/ASP.pm > $(DISTVNAME)/README',
  },
  clean             => {
  #      FILES => "@{ clean files() }",
  },
  ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
    (#ABSTRACT_FROM  => 'META.yml', # retrieve abstract from module
     AUTHOR         => 'John Drago <jdrago_999@yahoo.com>') : ()),
);

sub clean_files
{
  return [@scripts];
}# end clean_files()



