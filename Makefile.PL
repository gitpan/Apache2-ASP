use 5.008005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  NAME              => 'Apache2::ASP',
  VERSION_FROM      => 'lib/Apache2/ASP.pm', # finds $VERSION
  LICENSE           => 'artistic',
  EXE_FILES         => [qw( sbin/runasp sbin/asphelper )],
  PREREQ_PM         => {
    # Module                                    # Why is it needed?
    #==========================================================================
    Test::Memory::Cycle     => 1.04,            # For testing.
    Test::More              => 0.84,            # For testing.
    Time::HiRes             => 1.9715,          # For UploadHook frequency checks.
    HTTP::Body              => 1.04,            # HTTP POST parsing in test mode.
    Data::Properties::YAML  => 0.02,            # Properties files.
    XML::Simple             => 2.18,            # Configuration file parsing.
    CGI::Apache2::Wrapper   => 0.215,           # HTTP POST parsing.
    Cwd                     => 3.2701,          # Configuration file discovery.
    Digest::MD5             => 2.36,            # Session and Application state.
    DBI                     => 1.607,           # Session and Application state.
    DBD::SQLite             => 1.14,            # For testing.
    Storable                => 2.18,            # Session and Application state.
    HTTP::Date              => 5.810,           # For Session timeouts.
    MIME::Types             => 1.24,            # For MediaManager.
    Mail::Sendmail          => 0.79,            # For sending email.
    HTML::Form              => 5.817,           # For Apache2::ASP::Test::*
    HTTP::Request::AsCGI    => 0.5,             # For Apache2::ASP::Test::*
    CGI::Simple             => 1.106,           # For Apache2::ASP::Test::*
    Ima::DBI                => 0.35,            # For sessions & applications.
    XML::Parser             => 2.36,            # For XML::Simple.
    IO::File                => 1.14,            # For MediaManager
  }, # e.g., Module::Name => 1.1
  dist => {
    PREOP => 'pod2text lib/Apache2/ASP.pm > $(DISTVNAME)/README',
  },
  ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM  => 'lib/Apache2/ASP.pm', # retrieve abstract from module
     AUTHOR         => 'John Drago <jdrago_999@yahoo.com>') : ()),
);

