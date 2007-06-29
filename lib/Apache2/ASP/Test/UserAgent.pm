
package Apache2::ASP::Test::UserAgent;

use strict;
use warnings 'all';
use HTTP::Request::Common;
use HTTP::Response;
use HTTP::Request::AsCGI;
use Apache2::ASP::Test::MockRequest;
use CGI::Simple ();


#==============================================================================
sub new
{
  my ($class, $asp) = @_;
  $ENV{HTTP_COOKIE} ||= '';
  return bless {
    asp         => $asp,
    session_id  => 0,
    cookies     =>  { },
  }, $class;
}# end new()


#==============================================================================
sub submit_form
{
  my ($s, $form) = @_;
  
  my $req = $form->click;
  my $cgi = $s->_setup_cgi( $req );
  $ENV{CONTENT_TYPE} = $form->enctype ? $form->enctype : 'application/x-www-form-urlencoded';

#use Data::Dumper;
#warn "\n\tFORM: " . Dumper({ $cgi->Vars });

  my $r = Apache2::ASP::Test::MockRequest->new(
    req => $req,
    cgi => $cgi
  );
  
  $s->{asp}->setup_request( $r, $cgi );
  $s->{session_id} ||= $s->{asp}->session->{SessionID};
  return $s->_setup_response( $s->{asp}->execute() );
}# end submit_form()


#==============================================================================
sub asp
{
  $_[0]->{asp};
}# end asp()


#==============================================================================
sub add_cookie
{
  my ($s, $name, $value) = @_;
  
  $s->{cookies}->{$name} = $value;
}# end add_cookie()


#==============================================================================
sub get
{
  my ($s, $uri) = @_;
  
  my $req = GET $uri;
  my $cgi = $s->_setup_cgi( $req );
  $ENV{CONTENT_TYPE} ||= 'application/x-www-form-urlencoded';
  
  my $r = Apache2::ASP::Test::MockRequest->new(
    req => $req,
    cgi => $cgi
  );
  $s->{asp}->setup_request( $r, $cgi );
  $s->{session_id} ||= $s->{asp}->session->{SessionID};
  return $s->_setup_response( $s->{asp}->execute() );
}# end get()


#==============================================================================
sub post
{
  my ($s, $uri, $argref) = @_;
  
  my $req = POST $uri, $argref;
  $ENV{CONTENT_TYPE} = 'application/x-www-form-urlencoded';
  my $cgi = $s->_setup_cgi( $req );

  my $r = Apache2::ASP::Test::MockRequest->new(
    req => $req,
    cgi => $cgi
  );
  
  $s->{asp}->setup_request( $r, $cgi );
  $s->{session_id} ||= $s->{asp}->session->{SessionID};
  return $s->_setup_response( $s->{asp}->execute() );
}# end post()


#==============================================================================
sub upload
{
  my ($s, $uri, $argref) = @_;
  
  my $req = POST $uri, Content_Type => 'form-data', Content => $argref;
  my $cgi = $s->_setup_cgi( $req );
  
  $ENV{CONTENT_TYPE} = 'multipart/form-data';
  my $r = Apache2::ASP::Test::MockRequest->new(
    req => $req,
    cgi => $cgi
  );
  
  $s->{asp}->setup_request( $r, $cgi );
  $s->{session_id} ||= $s->{asp}->session->{SessionID};
  return $s->_setup_response( $s->{asp}->execute() );
}# end upload()


#==============================================================================
sub _setup_response
{
  my ($s, $response_code) = @_;
  my $response = HTTP::Response->new( $response_code );
  $response->content( $s->{asp}->r->buffer );
#warn "CONTENT: '" . $s->{asp}->r->buffer . "'";
  $response->header( 'Content-Type' => $s->{asp}->response->{ContentType} );
  foreach my $header ( $s->{asp}->response->Headers )
  {
    $response->header( %$header );
  }# end foreach()
  
  return $response;
}# end _setup_response()


#==============================================================================
sub _setup_cgi
{
  my ($s, $req) = @_;
  
  # Preserve our session cookie:
  if( $s->{asp}->session && $s->{asp}->session->{SessionID} )
  {
    $s->add_cookie( $s->{asp}->config->session_state->cookie_name => $s->{session_id} );
  }# end if()
  $s->{c}->DESTROY
    if $s->{c};
  $s->{asp} = ref($s->{asp})->new( $s->{asp}->config );
  $s->{c} = HTTP::Request::AsCGI->new($req)->setup;
  $ENV{SERVER_NAME}         = $ENV{HTTP_HOST} = 'localhost';
  
  # User-Agent:
  $req->header( 'User-Agent' => 'apache2-asp-test-useragent v1.0' );
  
  # Cookies:
  my @cookies = ();
  while( my ($name,$val) = each(%{ $s->{cookies} } ) )
  {
    push @cookies, "$name=" . CGI::Simple->url_encode($val);
  }# end while()
  $req->header( 'Cookie' => join ';', @cookies );
  $ENV{HTTP_COOKIE} = join ';', @cookies;

  # If it's a POST request we have to point STDIN to $req->content:
  if( $req->method =~ m/^post$/i )
  {
    # Get the POST data:
    $CGI::Simple::DISABLE_UPLOADS = 0;
    my $content = $req->content . '';
    open my $ifh, '<', \$content;
    my $cgi = CGI::Simple->new( $ifh );
    
    # Manually inject the Querystring data into the CGI object:
    my $qs_cgi = CGI::Simple->new( $ENV{QUERY_STRING} );
    $cgi->param( $_ => $qs_cgi->param( $_ ) ) foreach $qs_cgi->param;
    $qs_cgi->DESTROY;
    
    # Done:
    return $cgi;
  }
  else
  {
    # Simple 'GET' request:
    return CGI::Simple->new( $ENV{QUERY_STRING} );
  }# end if()
}# end _setup_cgi()

1;# return true:

__END__

=pod

=head1 SYNOPOSIS

  use Apache2::ASP::Test::UserAgent;
  
  my $ua = Apache2::ASP::Test::UserAgent->new( $asp );
  my $res = $ua->get( '/index.asp?abc=123' );
  if( $res->is_success )
  {
    is( $res->content, 'Hello, World!' );
  }
  else
  {
    die $res->status_line;
  }# end if()
  
  # Other request styles:
  my $post_res = $ua->post( '/handlers/FormHandler', [
    field1 => 'w00t!!',
    checkbox => [ a...z ],
  ]);
  my $upload_res = $ua->upload( '/handlers/UploadHandler', [
    field1 => 'w00t!!',
    some_filename => ['/path/to/file.txt']
  ]);

=cut
