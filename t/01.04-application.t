#!perl

use strict;
use warnings 'all';
use lib qw( ./t ../ );
use Mock;
#use Devel::Cover;
use Test::More 'no_plan';
use Test::Exception;
use Apache2::ASP;
use Apache2::ASP::Config;

# Start out simple:
use_ok('Apache2::ASP::ApplicationStateManager::SQLite');

# Initialize the config:
my $config = Apache2::ASP::Config->new();

# A fake Apache2::RequestRec object:
my $r = Mock->new(
  filename    => 'htdocs/index.asp',
  uri         => '/index.asp',
  headers_out => { },
);

# Setup our ASP object:
my $asp = Apache2::ASP->new( $config );
$asp->setup_request( $r );

my $Application = Apache2::ASP::ApplicationStateManager::SQLite->new( $asp );
isa_ok( $Application, 'Apache2::ASP::ApplicationStateManager::SQLite' );
isa_ok( $Application, 'Apache2::ASP::ApplicationStateManager' );
$Application->{__did_init} = 0;
$Application->save();
$Application = Apache2::ASP::ApplicationStateManager::SQLite->new( $asp );

# Now try storing and retrieving a value:
$Application->{foo} = 'bar';
$Application->save();
undef( $Application );
$Application = Apache2::ASP::ApplicationStateManager::SQLite->new( $asp );
is( $Application->{foo}, 'bar' );

# Now try making a new application:
$asp->config->{application_name} = 'AnotherApplication' . time();
my $app2 = ref($Application)->new( $asp );
isa_ok( $Application, 'Apache2::ASP::ApplicationStateManager' );

# Force the creation of a new dbh:
$Application->dbh->disconnect;
ok( $Application->dbh, '\$Application->dbh()' );

