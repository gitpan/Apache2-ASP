#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 110;

use lib '../';
use Cwd;

# Set the environment variable:
my $here = getcwd();
$ENV{APACHE2_ASP_APPLICATION_ROOT} = "$here/t";

# Load up some modules:
use_ok('Apache2::ASP::Application::MySQL');
use_ok('Apache2::ASP');
use_ok('DBI');
use_ok('DBD::SQLite');

# Set up the application database:
setup_application_database();

# Get an application object:
my $Application = setup_application();
isa_ok( $Application, 'Apache2::ASP::Application' );

# Put data in:
my $test_string = 'this is a test 'x80;
$Application->{test_field1} = $test_string;
is( $Application->{test_field1}, $test_string );

# Save it:
ok( $Application->save, 'save()' );

# Destroy and revive:
undef($Application);
is( $Application, undef );
$Application = setup_application();

# Make sure the newly-revived version contains the original data:
is( $Application->{test_field1}, $test_string );

# Load-tests:
for( 1...100 )
{
  undef($Application);
  $Application = setup_application();
  is( $Application->{test_field1}, $test_string );
  $Application->{test_field1} = 'sdf';
  $Application->save;
  $Application->{test_field1} = $test_string;
  $Application->save;
}# end for()



#==============================================================================
sub setup_application_database
{
  # Create the SQLite database:
  my $dbh = DBI->connect('DBI:SQLite:dbname=t/sessiontest');
  ok( $dbh, 'Connected to SQLite database');
  eval { $dbh->do('DROP TABLE asp_applications') };
  my $sth = $dbh->prepare(<<EOF);
  CREATE TABLE asp_applications (
    application_id VARCHAR(100) PRIMARY KEY NOT NULL,
    application_data BLOB
  );
EOF
  $sth->execute();
  $sth->finish();
  
  # Clobber the DSN environment variable:
  $ENV{APACHE2_ASP_STATE_DSN} = ['DBI:SQLite:dbname=t/sessiontest'];
}# end setup_application_database()


#==============================================================================
sub setup_application
{
  # Return a session:
  $ENV{HTTP_HOST} ||= 'localhost';
  return Apache2::ASP::Application::MySQL->new();
}# end setup_application()


