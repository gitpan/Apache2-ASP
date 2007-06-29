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
use Time::HiRes 'usleep';

# Start out simple:
use_ok('Apache2::ASP::UploadHandler');
use_ok('Apache2::ASP::UploadHookArgs');

# Initialize the config:
my $config = Apache2::ASP::Config->new();


# Pretend like we're doing a real request:
{
  my $uri = '/handlers/TestUploadHandler';
  my ( $asp ) = prepare_asp( $uri );
  $asp->execute( );
  my $handler = $asp->_resolve_request_handler( $uri );
#  $asp->_init_asp_objects( $handler );
  
  my $str = "This is the upload text\n"x8000;
  $ENV{CONTENT_LENGTH} = length($str);
  
  # Our upload struct:
  my $Upload = Apache2::ASP::UploadHookArgs->new(
    upload              => undef, # This would normally be an 'upload' object.
    percent_complete    => 0,
    elapsed_time        => 0,
    total_expected_time => 1,
    time_remaining      => 1,
    length_received     => 0,
    data                => '',
  );
  
  # Init the upload:
  $handler->upload_start( $asp, $Upload );
  
  # Call the upload_hook while we "upload" the data:
  for( 1...100 )
  {
    my $percent = $_ / 100;
    my $data = substr($str, 0, (length($str) * $percent));
    $Upload->{percent_complete} = $_;
    $Upload->{elapsed_time} = 1;
    $Upload->{time_remaining} = 1;
    $Upload->{length_received} = int($Upload->content_length * ( $_ / 100 ) );
    $Upload->{data} = $data;
    
    # Init the upload:
    $handler->upload_hook( $asp, $Upload );
    usleep( 10000 );
  }# end for()
  
  # Finish the upload:
  $Upload->{percent_complete} = 100;
  $Upload->{elapsed_time} = 1;
  $Upload->{time_remaining} = 0;
  $Upload->{length_received} = length($str);
  $Upload->{data} = undef;
  $handler->upload_end( $asp, $Upload );
  
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
  
  $asp->setup_request( $r );
  
  return ( $asp );
}# end prepare_asp()



