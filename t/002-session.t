#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 113;

use lib '../';
use Cwd;

# Set the environment variable:
my $here = getcwd();
$ENV{APACHE2_APPLICATION_ROOT} = "$here/t";

# Load up some modules:
use_ok('Apache2::ASP::Session');
use_ok('Apache2::ASP');
use_ok('DBI');
use_ok('DBD::SQLite');

# Set up the session database:
setup_session_database();
  
# Get a mock Apache request:
my $r = Apache2::ASP::MockRequest->new();
isa_ok( $r, 'Apache2::ASP::MockRequest' );

# Get a session object:
my $Session = setup_session();
isa_ok( $Session, 'Apache2::ASP::Session' );

# Put data in:
my $test_string = 'this is a test 'x80;
$Session->{test_field1} = $test_string;
is( $Session->{test_field1}, $test_string );

# Save it:
ok( $Session->save, 'save()' );

# Destroy and revive:
my $session_id = $Session->{SessionID};
ok( $session_id, 'SessionID' );
undef($Session);
is( $Session, undef );
$Session = setup_session( $session_id );

# Make sure the newly-revived version contains the original data:
is( $Session->{test_field1}, $test_string );

# Load-tests:
for( 1...100 )
{
  undef($Session);
  $Session = setup_session( $session_id );
  is( $Session->{test_field1}, $test_string );
  $Session->{test_field1} = 'sdf';
  $Session->save;
  $Session->{test_field1} = $test_string;
  $Session->save;
}# end for()

# Try abandonment:
$Session->Abandon;

# Make sure the abandonment worked:
is( $Session->{test_field1}, undef );


#==============================================================================
sub setup_session_database
{
  # Create the SQLite database:
  my $dbh = DBI->connect('DBI:SQLite:dbname=t/sessiontest');
  ok( $dbh, 'Connected to SQLite database');
  eval { $dbh->do('DROP TABLE asp_sessions') };
  my $sth = $dbh->prepare(<<EOF);
  CREATE TABLE asp_sessions (
    session_id CHAR(32) PRIMARY KEY NOT NULL,
    session_data BLOB,
    created_on DATETIME,
    modified_on DATETIME
  );
EOF
  $sth->execute();
  $sth->finish();
  
  # Clobber the DSN environment variable:
  $ENV{APACHE2_ASP_SESSION_DSN} = ['DBI:SQLite:dbname=t/sessiontest'];
}# end setup_session_database()


#==============================================================================
sub setup_session
{
  my $session_id = shift;
  
  # Finally - return a session:
  return Apache2::ASP::Session->new( $session_id, $r );
}# end setup_session()


