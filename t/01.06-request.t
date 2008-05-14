#!perl

use strict;
use warnings 'all';
use Test::More 'no_plan';
use Test::Exception;

use base 'Apache2::ASP::Test::Base';

# Initialize our object:
my $s = __PACKAGE__->SUPER::new();

use_ok('Apache2::ASP::Request');

use Apache2::ASP::Base;
use Apache2::ASP::Config;
use Apache2::ASP::Test::UserAgent;

$s->ua->add_cookie( name => 'value' );
$s->ua->add_cookie( name2 => 'val1=1&val2=2' );
$s->ua->get( '/index.asp?field1=value1' );

my $Request = $s->ua->asp->request;




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
$Request->Cookies( );
is( $Request->Cookies( 'name2', 'val2' ), 2 );

# Passing in 'undef' for the key name should return undef:
is( $Request->Cookies( 'name2', undef ), undef );

is( $Request->Cookies( 'name-doesnt-exist', undef ), undef );
is( $Request->Cookies( 'name-doesnt-exist', 'val2' ), undef );
is( $Request->Cookies( 'name2', 'key-doesnt-exist' ), undef );
is( $Request->Cookies( undef, 'val2' ), undef );
is( $Request->Cookies(), 2 );



is( $Request->Cookies( undef, undef, undef ), undef );


# Form:
{
  can_ok( $Request, 'Form' );
  my $Form = $Request->Form;
  ok( ref($Form), 'HASH' );
  is( $Request->Form('not_there'), undef );
  is( $Request->Form('field1'), 'value1' );
	
	$s->session->{_lastArgs} = {
		color => 'Yellow',
		name  => 'banana',
	};
	$s->ua->get('/index.asp');
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


#


