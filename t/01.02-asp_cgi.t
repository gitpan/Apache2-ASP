#!perl

# This is necessary to keep CGI::Apache2::Wrapper from complaining too much :)
package Apache2::RequestRec;

sub upload_hook { 1 }
sub connection { 1 }
sub APR::Request::Apache2::handle { return bless {}, 'Apache2::RequestRec' }

package main;

use strict;
use warnings 'all';
use lib qw( ./t ../ );
use Mock;
use Cwd 'cwd';
#use Devel::Cover;
use Test::More 'no_plan';
use Test::Exception;
use Apache2::ASP::Config;

# Start out simple:
use_ok('Apache2::ASP::CGI');

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
  connection   => 1,
);


# This is also necessary to keep CGI::Apache2::Wrapper from complaining too much :)
$INC{'APR/Request.pm'}          = 'ok';
$INC{'APR/Request/Param.pm'}    = 'ok';
$INC{'APR/Request/Apache2.pm'}  = 'ok';
sub APR::Request::Param::upload_type { }
sub APR::Request::Param::upload_size { }
sub APR::Request::Param::upload_tempname { }
sub APR::Request::Param::upload_filename { }

# Hack hack hack...
bless $r, 'Apache2::RequestRec';
ok( my $cgi = Apache2::ASP::CGI->new( $r ) );
ok( $cgi = Apache2::ASP::CGI->new( $r, sub { } ) );

# Yay 100% coverage!

