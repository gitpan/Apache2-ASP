use 5.008005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
use lib qw( ../blib/lib lib );

# Prerequisites:
my %require = (
  'HTTP::Body'              => 1.01,
  'Data::Properties::YAML'  => 0.02,
  'Devel::StackTrace'       => 0,
  'XML::Simple'             => 0,
  'CGI::Apache2::Wrapper'   => 0,
  'Cwd'                     => 0,
  'Digest::MD5'             => 0,
  'DBI'                     => 0,
  'DBD::SQLite'             => 0,     # Default state-persistence backend for testing.
  'Storable'                => 0,
  'HTTP::Date'              => 0,
  'DateTime::Duration'      => 0,
  'MIME::Types'             => 0,
  'Mail::Sendmail'          => 0,
  'Sys::Hostname'           => 0,
  'Apache2::Directive'      => 0,
  'HTML::Form'              => 0,
  'HTTP::Request::AsCGI'    => 0,     # For Apache2::ASP::Test::*
  'CGI::Simple'             => 0,     # For Apache2::ASP::Test::*
  'HTML::Form'              => 0,     # For Apache2::ASP::Test::*
  'Ima::DBI'                => 0.35,  # For sessions & applications.
);

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
}# end clean_files()



