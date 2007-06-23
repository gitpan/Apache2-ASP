#!perl

use strict;
use warnings 'all';
use lib './t';
use Mock;
#use Devel::Cover;
use Test::More 'no_plan';
use Test::Exception;
use Apache2::ASP;
use Apache2::ASP::Config;

# Start out simple:
use_ok('Apache2::ASP::SessionStateManager::SQLite');

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

my $Session = Apache2::ASP::SessionStateManager::SQLite->new( $asp );
isa_ok( $Session, 'Apache2::ASP::SessionStateManager::SQLite' );
isa_ok( $Session, 'Apache2::ASP::SessionStateManager' );
$Session->save();

# Check to make sure the cookie would have been written:
#ok( $r->headers_out->{'Set-Cookie'} =~ m/\=$Session->{SessionID}\b/ );
my $headers = $asp->response->Headers;
my ($header) = grep { $_ eq 'Set-Cookie' && $headers->{$_} =~ m/\=$Session->{SessionID}\b/ } keys( %$headers );
ok( $header, 'Set-Cookie for sessions works' );

#warn "\n\tID: $Session->{SessionID}\n";

# Round-about way to get a session id:
my $session_id = $Session->new_session_id();
ok( $session_id );
$ENV{HTTP_COOKIE} = $config->session_state->cookie_name . '=' . $session_id;
is( $Session->parse_session_id(), $session_id );

# If we have a session cookie, are we using that value instead of generating a new one?
$Session = Apache2::ASP::SessionStateManager::SQLite->new( $asp );
$session_id = $Session->{SessionID};
$ENV{HTTP_COOKIE} = $config->session_state->cookie_name . '=' . $session_id;
$Session = Apache2::ASP::SessionStateManager::SQLite->new( $asp );
is( $Session->{SessionID}, $session_id );

# The session id is verifyable:
ok( $Session->verify_session_id( $session_id ) );
