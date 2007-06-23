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
use_ok('Apache2::ASP::Request');

# Initialize the config:
my $config = Apache2::ASP::Config->new();

# A fake Apache2::RequestRec object:
my $r = Mock->new(
  filename    => 'htdocs/index.asp',
  uri         => '/index.asp',
  headers_out => { },
  headers_in  => { },
  cookie      => 'name=value',
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

my $Request = Apache2::ASP::Request->new( $asp );

# COOKIES!
can_ok( $Request, 'Cookies' );
is( $Request->Cookies('doesnotexist'), undef );
is( $Request->Cookies('name'), 'value' );
my $hash_cookie = $Request->Cookies('name2');
ok( $hash_cookie );
is_deeply(
  $hash_cookie, {
    val1 => 1,
    val2 => 2,
  }
);
is( $Request->Cookies('name2', 'val1'), 1);


# Form:
{
  can_ok( $Request, 'Form' );
  my $Form = $Request->Form;
  ok( ref($Form), 'HASH' );
  is( $Request->Form('not_there'), undef );
  is( $Request->Form('field1'), 'value1' );
}

# QueryString:
is( $Request->QueryString, $ENV{HTTP_QUERYSTRING} );

# ServerVariables:
is( $Request->ServerVariables("HTTP_QUERYSTRING"), $ENV{HTTP_QUERYSTRING} );
my @vars = $Request->ServerVariables;

#ok( scalar(), "\$Request->ServerVariables() returns a list of available parameters" );

# FileUpload:
{
  # $field && ( ! wantarray )
  my $info1 = $Request->FileUpload('filename');
  
  # $field && wantarray
  my %info2 = $Request->FileUpload('filename');
  
  # $field && $arg && ( ! wantarray )
  my $about = $Request->FileUpload('filename', 'ContentType' );
  
  # $field && $arg && wantarray 
  my %about = $Request->FileUpload('filename', 'ContentType' );
  
  # Nothing - fail:
  dies_ok
    { $Request->FileUpload }
    "\$Request->FileUpload without arguments fails";
}


