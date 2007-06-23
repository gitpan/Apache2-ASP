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
use_ok('Apache2::ASP::Handler');

# Initialize the config:
my $config = Apache2::ASP::Config->new();


# Pretend like we're doing a real request:
{
  my $uri = '/handlers/TestHandler';
  my ($r, $subref) = prepare_asp( $uri );
  lives_ok { $subref->( 0 ) };
  is( $r->{buffer}, 'This is the default handler response.' );
}



#==============================================================================
sub prepare_asp
{
  my ($uri) = @_;
  
  # A fake Apache2::RequestRec object:
  my $r = Mock->new(
    filename    => "htdocs/$uri",
    uri         => $uri,
    headers_out => { },
    headers_in  => { },
    cookie      => 'name=value',
    pool        => Mock->new(
      cleanup_register => 1
    ),
    content_type => 'text/html',
    status       => '200',
  );
  
  # Setup our ASP object:
  $ENV{HTTP_QUERYSTRING} = 'field1=value1&field2=value2&filename=C:\\MyFile.txt';
  my $asp = Apache2::ASP->new( $config );
  my $subref = $asp->setup_request( $r );
  
  my $Session = $asp->session;
  $Session->save();
  $ENV{HTTP_COOKIE} = $config->session_state->cookie_name . '=' . $Session->{SessionID} . ';name=value;name2=val1%3D1%26val2%3D2';
  $asp->{r}->headers_in({
    'HTTP_COOKIE' => $config->session_state->cookie_name . '=' . $Session->{SessionID} . ';name=value;name2=val1%3D1%26val2%3D2'
  });
  
  return ($r, $subref);
}# end prepare_asp()



