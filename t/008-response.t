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
use HTTP::Date qw( time2str );

# Start out simple:
use_ok('Apache2::ASP::Response');

# Initialize the config:
my $config = Apache2::ASP::Config->new();

# A fake Apache2::RequestRec object:
my $r = Mock->new(
  filename      => 'htdocs/index.asp',
  uri           => '/index.asp',
  headers_out   => { },
  headers_in    => { },
  cookie        => 'name=value',
  content_type  => 'text/html',
  status        => '200 OK',
  connection    => Mock->new(
    client_socket => Mock->new(
      close => 1,
    ),
    aborted => 0
  )
);

# Setup our ASP object:
$ENV{HTTP_QUERYSTRING} = 'field1=value1&field2=value2&filename=C:\\MyFile.txt';
my $asp = Apache2::ASP->new( $config );
$asp->setup_request( $r );
$asp->{q} = $asp->{r};

my $Session = Apache2::ASP::SessionStateManager::SQLite->new( $asp );
$Session->save();
$ENV{HTTP_COOKIE} = $config->session_state->cookie_name . '=' . $Session->{SessionID};
#$asp->{r}->headers_in({
#  'HTTP_COOKIE' => $config->session_state->cookie_name . '=' . $Session->{SessionID}
#});

# Pretend like we're doing a real request:
my $handler = $asp->_resolve_request_handler( '/index.asp' );
#$asp->_init_asp_objects( $handler );

# Is it what we think it is?
my $Response = $asp->response;
ok( $Response );
isa_ok( $Response, 'Apache2::ASP::Response' );

# Can we clear the buffer?
$Response->Clear;

# Can we redirect?
$Response->Redirect( "/new/url.asp" );
is( $r->{status}, 302 );
is( $r->headers_out->{Location}, '/new/url.asp' );

# Refresh our ASP objects:
#$asp->_init_asp_objects( $handler );
$Response = $asp->response;

# Try writing:
my $test_string = 'test string';
$Response->Write($test_string);
$Response->Flush;
is( $r->{buffer}, $test_string );
$Response->Write( undef );
$Response->Flush;

$Response->{Buffer} = 0;
$Response->Write('ok');
$Response->Flush;

# Try adding a header:
$Response->AddHeader( 'x-myheader' => 'myvalue' );
is( $Response->{_headers}->[0]->{name}, 'x-myheader' );

# Try adding a cookie:
$Response->Cookies( 'mycookie' => 'cookievalue' );
is( $Response->{_headers}->[1]->{name}, 'Set-Cookie' );

# Try redirecting now, after status has been sent:
throws_ok
  { $Response->Redirect( "/new/url.asp" ) }
  qr/Response\.Redirect: Cannot redirect after headers have been sent\./;

# Is the client connected?
ok( $Response->IsClientConnected );
$r->connection->aborted( 1 );
is( $Response->IsClientConnected, '' );
$r->connection->aborted( 0 );

# Can we Include something?
#lives_ok
#  { $Response->Include( $config->www_root . '/index.asp' ) }
#  '$Response->Include(...) works';
#dies_ok
#  { $Response->Include( '/undksdlfkjsdfsdfsdf.asp' ) };
#dies_ok
#  { $Response->Include( $config->www_root . '/syntax_error.asp' ) };
#
## Can we TrapInclude something?
#lives_ok
#  { $Response->TrapInclude( $config->www_root . '/index.asp' ) }
#  '$Response->TrapInclude(...) works';
#dies_ok
#  { $Response->TrapInclude( '/undksdlfkjsdfsdfsdf.asp' ) };
#dies_ok
#  { $Response->TrapInclude( $config->www_root . '/syntax_error.asp' ) };


# Just make 100% coverage:
$Response->Buffer(0);
is( $Response->Buffer, 0 );
ok( $Response->Buffer( 1 ) );
is( $Response->Buffer, 1 );
$Response->Buffer( 0 );
is( $Response->Buffer, 0 );

# Make sure the default expiration is *now*:
is( $Response->Expires, 0 );

# Expires in the future:
$Response->Expires( 30 );
is( $Response->Expires, 30 );
my $absolute = time2str( time() + $Response->{Expires} );
is( $Response->ExpiresAbsolute, $absolute );

# Expired in the past:
$Response->Expires( -30 );
is( $Response->Expires, -30 );
$absolute = time2str( time() + $Response->{Expires} );
is( $Response->ExpiresAbsolute, $absolute );


