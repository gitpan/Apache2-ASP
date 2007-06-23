#!perl

use strict;
use warnings 'all';
use lib './t';
use Mock;
use Cwd 'cwd';
#use Devel::Cover;
use Test::More 'no_plan';
use Test::Exception;
use Apache2::ASP;
use Apache2::ASP::Config;

# Start out simple:
use_ok('Apache2::ASP::Server');

# Initialize the config:
my $config = Apache2::ASP::Config->new();

# A fake Apache2::RequestRec object:
my $r = Mock->new(
  filename    => 'htdocs/index.asp',
  uri         => '/index.asp',
  headers_out => { },
  headers_in  => { },
  cookie      => 'name=value',
  pool        => Mock->new(
    cleanup_register => 1
  )
);

# Setup our ASP object:
$ENV{HTTP_QUERYSTRING} = 'field1=value1&field2=value2&filename=C:\\MyFile.txt';
my $asp = Apache2::ASP->new( $config );
$asp->setup_request( $r );
$asp->{q} = $asp->{r};

my $Session = Apache2::ASP::SessionStateManager::SQLite->new( $asp );
$Session->save();
$ENV{HTTP_COOKIE} = $config->session_state->cookie_name . '=' . $Session->{SessionID} . ';name=value;name2=val1%3D1%26val2%3D2';
#$asp->{r}->headers_in({
#  'HTTP_COOKIE' => $config->session_state->cookie_name . '=' . $Session->{SessionID} . ';name=value;name2=val1%3D1%26val2%3D2'
#});

# Pretend like we're doing a real request:
my $handler = $asp->_resolve_request_handler( '/index.asp' );
#$asp->_init_asp_objects( $handler );

# Make sure we have the real thing:
my $Server = $asp->server;
isa_ok( $Server, 'Apache2::ASP::Server' );

# Can we MapPath?
my $result = $Server->MapPath( "/index.asp" );
ok( -f $result );
$Server->{r}->{disable_lookup_uri} = 1;
is( $Server->MapPath("/test.asp"), undef );
$Server->{r}->{disable_lookup_uri} = 0;

# Can we URLEncode?
is( $Server->URLEncode('@'), '%40' );

# Can we HTMLEncode?
is( $Server->HTMLEncode('<b>OK</b>'), '&lt;b&gt;OK&lt;/b&gt;' );

# Can we HTMLDecode?
is( $Server->HTMLDecode('&lt;b&gt;OK&lt;/b&gt;'), '<b>OK</b>' );

# Can we email someone?
my $res = $Server->Mail(
  To  => 'test@apache2-asp.no-ip.org',
  From => 'test@localhost',
  Subject => 'Apache2::ASP Test Run',
  Message => 'This is the test.  Thanks for writing back.'
);
ok( $res, '$Server->Mail(...) works' );

# Can we register a cleanup handler?
ok( $Server->RegisterCleanup(sub{ 1 }), '$Server->RegisterCleanup(sub{})' );

