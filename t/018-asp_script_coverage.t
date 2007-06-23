#!perl

use strict;
use warnings 'all';
use lib qw(
  ./t
  ./t/PAGE_CACHE/DefaultApp
);
use Mock;
use Cwd 'cwd';
#use Devel::Cover -select => qr@t/PAGE_CACHE/DefaultApp@;
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





