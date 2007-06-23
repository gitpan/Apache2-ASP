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
use_ok('Apache2::ASP::PageHandler');

# Initialize the config:
my $config = Apache2::ASP::Config->new();


# Pretend like we're doing a real request:
{
  my $asp = prepare_asp( '/index.asp' );
  my $handler = $asp->_resolve_request_handler( '/index.asp' );
#  $asp->_init_asp_objects( $handler );
  lives_ok { $handler->run( $asp ) };
  is( $asp->{r}->{buffer}, 'Hello, World!' );
}


# The requested page should die because of a syntax error:
{
  my $asp = prepare_asp( '/syntax_error.asp' );
  my $handler = $asp->_resolve_request_handler( '/syntax_error.asp' );
#  $asp->_init_asp_objects( $handler );
  dies_ok
    { $handler->run( $asp ) }
    "Syntax error in ASP script causes an exception to be thrown";
}


# Write a page, execute it, update it, execute it again:
{
  my $filename = $config->www_root . '/updated.asp';
  unlink( $filename ) if -f $filename;
  open my $ofh, '>', $filename
    or die "Cannot open '$filename' for writing: $!";
  print $ofh '<%= "Original" %>';
  close($ofh);
  
  {
    my $asp = prepare_asp( "/updated.asp" );
    my $handler = $asp->_resolve_request_handler( "/updated.asp" );
#    $asp->_init_asp_objects( $handler );
    $handler->run( $asp );
  }
  
  open $ofh, '>', $filename
    or die "Cannot open '$filename' for writing: $!";
  print $ofh '<%= "Updated" %>';
  close($ofh);
  
  {
    my $asp = prepare_asp( "/updated.asp" );
    my $handler = $asp->_resolve_request_handler( "/updated.asp" );
#    $asp->_init_asp_objects( $handler );
    $handler->run( $asp );
  }
  
  {
    my $asp = prepare_asp( "/does-not-exist.asp" );
    my $handler = $asp->_resolve_request_handler( "/does-not-exist.asp" );
#    $asp->_init_asp_objects( $handler );
    dies_ok
      { $handler->run( $asp ) }
      "Fails when the page does not exist.";
  }
}

{
  my $asp = prepare_asp( '/index.asp' );
  my $handler = $asp->_resolve_request_handler( '/index.asp' );
#  $asp->_init_asp_objects( $handler );
  my $page_handler = bless { asp => $asp }, 'Apache2::ASP::PageHandler';
  my $package_filename = '/cannot/access/path.pm';
  my $asp_filename = '/file/doesnt/exist.asp';
  my $full_package_name = 'class::doesnt::exist';
  dies_ok
    { $page_handler->compile_asp( $package_filename, $asp_filename, $full_package_name ) }
    "Fails with an attempt to compile an ASP that doesn't exist.";
  $asp_filename = $config->www_root . '/index.asp';
  dies_ok
    { $page_handler->compile_asp( $package_filename, $asp_filename, $full_package_name ) }
    "Fails with an attempt to use an invalid package_filename.";
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



