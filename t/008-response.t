#!perl

use strict;
use warnings 'all';
use lib './t';
use Mock;
#use Devel::Cover;
use Test::More 'no_plan';
use Test::Exception;
use Apache2::ASP::Base;
use Apache2::ASP::Config;
use Apache2::ASP::Test::UserAgent;
use HTTP::Date qw( time2str );

# Start out simple:
use_ok('Apache2::ASP::Response');

my $config = Apache2::ASP::Config->new();
my $asp = Apache2::ASP::Base->new( $config );
my $ua = Apache2::ASP::Test::UserAgent->new( $asp );
$ua->get( '/index.asp' );
$asp = $ua->asp;

# Is it what we think it is?
my $Response = $asp->response;
ok( $Response );
isa_ok( $Response, 'Apache2::ASP::Response' );

# Can we clear the buffer?
$Response->Clear;

# Can we redirect?
$Response->{_sent_headers} = 0;
$Response->Redirect( "/new/url.asp" );
is( $asp->r->{status}, 302 );
is( $asp->r->headers_out->{Location}, '/new/url.asp' );

# Refresh our ASP objects:
#$asp->_init_asp_objects( $handler );
$Response = $asp->response;
$asp->r->{buffer} = '';

# Try writing:
my $test_string = 'test string';
$Response->Write($test_string);
$Response->Flush;
is( $asp->r->{buffer}, $test_string );
$Response->Write( undef );
$Response->Flush;

$Response->{Buffer} = 0;
$Response->Write('ok');
$Response->Flush;

# Try adding a header:
$Response->AddHeader( 'x-myheader' => 'myvalue' );
my $headers = $Response->Headers;
my ($header) = grep { $_ eq 'x-myheader' } keys( %$headers );
is( $header, 'x-myheader' );

# Try adding a cookie:
$Response->Cookies( 'mycookie' => 'cookievalue' );
is( $Response->{_headers}->[1]->{name}, 'Set-Cookie' );

# Try redirecting now, after status has been sent:
throws_ok
  { $Response->Redirect( "/new/url.asp" ) }
  qr/Response\.Redirect: Cannot redirect after headers have been sent\./;

# Is the client connected?
$Response->{r}->connection->aborted( 0 );
ok( $Response->IsClientConnected );
#
#
#$Response->{r}->connection->aborted( 1 );
#is( $Response->IsClientConnected, '' );

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


