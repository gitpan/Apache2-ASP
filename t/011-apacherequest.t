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
use_ok('Apache2::ASP::ApacheRequest');

# Initialize the config:
my $config = Apache2::ASP::Config->new();


# Pretend like we're doing a real request:
{
  my $uri = '/index.asp';
  my $asp_filename = $config->www_root . $uri;
  my $asp = prepare_asp( $uri );
  my $handler = $asp->_resolve_request_handler( $uri );
#  $asp->_init_asp_objects( $handler );
  my $r = $asp->{r};
  local $asp->{r} = Apache2::ASP::ApacheRequest->new(
    r             => $r->{r},
    uri           => $uri,
    status        => '200 OK',
    filename      => $asp_filename,
    content_type  => 'text/html',
    headers_out   => { },
    headers_in    => { },
    cookie        => 'name=value',
    pool          => Mock->new(
      cleanup_register => 1
    )
  );
  local $r->{cleanup_register} = sub {
    1;
  };
  
  $asp->{r}->uploadInfo();
  $asp->{r}->upload();
  $asp->{r}->param();
  $asp->{r}->param('some_field_name');
  $asp->{r}->escape('sdf');
  $asp->{r}->unescape('sdf');
  $asp->{r}->lookup_uri( $uri );
  {
    local $asp->{r}->{disable_lookup_uri} = 1;
    $asp->{r}->lookup_uri();
  }
  $asp->{r}->rflush();
  $asp->{r}->headers_out( $asp->{r}->headers_out );
  $asp->{r}->buffer();
  
  dies_ok
    { $asp->{r}->invalid_method };
  lives_ok
    { $asp->{r}->status };
  lives_ok
    { $asp->{r}->status(200) };
  lives_ok
    { $asp->{r}->pool->cleanup_register };
  
  $asp->{r}->print('ok');
  
}

# Try creating an object without passing in all the params:
{
  dies_ok{ Apache2::ASP::ApacheRequest->new() };
}


#==============================================================================
sub prepare_asp
{
  my ($uri) = @_;
  
  # A fake Apache2::RequestRec object:
  my $r = Mock->new(
    r           => Mock->new(
      filename    => "htdocs/$uri",
      uri         => $uri,
    ),
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
  $asp->setup_request( $r );
  $asp->{q} = $asp->{r};
  
  my $Session = Apache2::ASP::SessionStateManager::SQLite->new( $asp );
  $Session->save();
  $ENV{HTTP_COOKIE} = $config->session_state->cookie_name . '=' . $Session->{SessionID} . ';name=value;name2=val1%3D1%26val2%3D2';
  $asp->{r}->headers_in({
    'HTTP_COOKIE' => $config->session_state->cookie_name . '=' . $Session->{SessionID} . ';name=value;name2=val1%3D1%26val2%3D2'
  });
  
  return $asp;
}# end prepare_asp()



