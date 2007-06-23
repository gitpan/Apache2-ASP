#!perl

use strict;
use warnings 'all';
use lib './t';
use Mock;
use Cwd 'cwd';
#use Devel::Cover;
use Test::More 'no_plan';
use Test::Exception;
use Apache2::ASP::Config;
use CGI ();

# Start out simple:
use_ok('Apache2::ASP::Base');

# Initialize the config:
my $config = Apache2::ASP::Config->new();

# Setup a mock request:
my $r = Mock->new(
  filename    => "htdocs/index.asp",
  uri         => '/index.asp',
  headers_out => { },
  headers_in  => { },
  cookie      => 'name=value',
  pool        => Mock->new(
    cleanup_register => 1
  ),
  content_type => 'text/html',
  status       => '200',
);

# Ready our ASP object:
my $asp = Apache2::ASP::Base->new( $config );

# Try executing some page:
my $subref = $asp->setup_request( $r );
lives_ok
  { $subref->( 0 ) }
  '$subref->( 0 ) lives';
like( $r->buffer, qr/Hello, World\!/, '$subref->() works' );
$r->buffer('');

# Try executing some page with a syntax error:
$r->filename( 'htdocs/syntax_error.asp' );
$r->uri( '/syntax_error.asp' );
$subref = $asp->setup_request( $r );
lives_ok
  { $subref->( 0 ) }
  '$subref->( 0 ) lives with a syntax error';
$r->buffer('');

# Try executing some page with a runtime error:
$r->filename( 'htdocs/runtime_error.asp' );
$r->uri( '/runtime_error.asp' );
$subref = $asp->setup_request( $r );
lives_ok
  { $subref->( 0 ) }
  '$subref->( 0 ) lives with a runtime error';
$r->buffer('');

# Also try passing in our own CGI object:
$r->filename( 'htdocs/index.asp' );
$r->uri( '/index.asp' );
$subref = $asp->setup_request( $r, CGI->new() );
lives_ok
  { $subref->( 0 ) }
  '$subref->( 0 ) lives with a CGI object';
like( $r->buffer, qr/Hello, World\!/, '$subref->() works with a CGI object' );
$r->buffer('');

# Now try executing it as a subrequest:
$subref = $asp->setup_request( $r );
lives_ok
  { $subref->( 1 ) }
  '$subref->( 1 ) lives';
like( $r->buffer, qr/Hello, World\!/, '$subref->( 1 ) works' );
$r->buffer('');

# Now try it when we would be accessing a regular Handler instead:
$r->filename( 'handlers/TestHandler.pm' );
$r->uri( '/handlers/TestHandler' );
$subref = $asp->setup_request( $r );
lives_ok
  { $subref->( 0 ) }
  '$subref->( 0 ) lives for handlers too';
$r->buffer('');

# Execute a handler:
$subref = $asp->setup_request( $r );
lives_ok
  { $subref->( 0 ) }
  '$subref->( 0 ) lives for handlers too';
like( $r->buffer, qr/Default handler response/i, '$subref->( 0 ) works for handlers' );
$r->buffer('');

# Execute a handler as a subrequest:
$subref = $asp->setup_request( $r );
lives_ok
  { $subref->( 1 ) }
  '$subref->( 1 ) works for handlers too';
like( $r->buffer, qr/Default handler response/i, '$subref->( 1 ) works for handlers' );
$r->buffer('');

# Now change it to a different kind of URI:
$r->uri( '/index.html' );
$subref = $asp->setup_request( $r );
lives_ok
  { $subref->( 0 ) }
  '/index.html';
$r->buffer('');

# Now try Includes:
$r->buffer('');
$r->uri( '/has_include.asp' );
$r->filename( $config->www_root . '/has_include.asp' );
$subref = $asp->setup_request( $r );
lives_ok
  { $subref->( 0 ) }
  '/has_include.asp';
like( $r->buffer, qr/ABOVE\s+Include Goes Here\s+BELOW/i, 'Include() works' );

# Now try TrapIncludes:
$r->buffer('');
$r->uri( '/trapinclude.asp' );
$r->filename( $config->www_root . '/has_include.asp' );
$subref = $asp->setup_request( $r );
lives_ok
  { $subref->( 0 ) }
  '/has_include.asp';
like( $r->buffer, qr/Before\s+Include Goes Here\s+After/i, 'TrapInclude works' );

# Make sure the globals got initialized for the GlobalASA:
no warnings 'once';
isa_ok( $GlobalASA::Request, 'Apache2::ASP::Request' );

# Now try accessing a Handler with a valid mode:
{
  $r->filename( 'handlers/TestHandler.pm' );
  $r->uri( '/handlers/TestHandler' );
  $subref = $asp->setup_request( $r );
  $asp->q->param('mode', 'special_mode' );
  $r->buffer('');
  lives_ok { $subref->( 0 ) };
  is( $r->buffer, 'special_mode works' );
}

# Now try accessing a Handler with an invalid mode:
{
  $r->filename( 'handlers/TestHandler.pm' );
  $r->uri( '/handlers/TestHandler' );
  $subref = $asp->setup_request( $r );
  $asp->q->param('mode', 'mode_that_doesnt_exist' );
  $r->buffer('');
  lives_ok { $subref->( 0 ) };
  is( $r->buffer, "Unknown mode 'mode_that_doesnt_exist'." );
}

