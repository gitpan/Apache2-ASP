
package Apache2::ASP::Test::UserAgent;

use strict;
use warnings 'all';
use HTTP::Request::Common;
use HTTP::Response;
use HTTP::Request::AsCGI;
use HTTP::Body;
use Apache2::ASP::HTTPContext;
use Apache2::ASP::SimpleCGI;
use Apache2::ASP::Mock::RequestRec;
use Carp 'confess';

our $ContextClass = 'Apache2::ASP::HTTPContext';


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  return bless {
    %args,
  }, $class;
}# end new()


#==============================================================================
sub context { Apache2::ASP::HTTPContext->current || $Apache2::ASP::HTTPContext::ClassName->new }


#==============================================================================
sub post
{
  my ($s, $uri, $args) = @_;
  
  no strict 'refs';
  undef(${"$ContextClass\::instance"});
  $args ||= [ ];
  my $req = POST $uri, $args;
  %ENV = ( );
  $ENV{REQUEST_METHOD} = 'POST';
  my $cgi = $s->_setup_cgi( $req );
  $ENV{CONTENT_TYPE} = 'application/x-www-form-urlencoded';
  
  my $r = Apache2::ASP::Mock::RequestRec->new();
  $r->uri( $uri );
  $r->args( $cgi->{querystring} );
  
  $s->context->setup_request( $r, $cgi );
  return $s->_setup_response( $s->context->execute() );
}# end post()


#==============================================================================
sub upload
{
  my ($s, $uri, $args) = @_;
  
  no strict 'refs';
  undef(${"$ContextClass\::instance"});
  %ENV = ( );
  my $req = POST $uri, Content_Type => 'form-data', Content => $args;
  $ENV{REQUEST_METHOD} = 'POST';
  $ENV{CONTENT_TYPE} = $req->headers->{'content-type'};
  my $cgi = $s->_setup_cgi( $req );
  $ENV{CONTENT_TYPE} = 'multipart/form-data';
  
  my $r = Apache2::ASP::Mock::RequestRec->new();
  $r->uri( $uri );
  $r->args( $cgi->{querystring} );
  
  $s->context->setup_request( $r, $cgi );
  
  require Apache2::ASP::UploadHook;
  my $hook_obj = Apache2::ASP::UploadHook->new(
    handler_class => $s->context->resolve_request_handler( $uri ),
  );
  my $hook_ref = sub { $hook_obj->hook( @_ ) };
  
  # Now call the upload hook...
  require Apache2::ASP::Test::UploadObject;
  foreach my $uploaded_file ( keys( %{ $cgi->{uploads} } ) )
  {
    my $tmpfile = $cgi->upload_info($uploaded_file, 'tempname' );
    my $filename = $cgi->upload_info( $uploaded_file, 'filename' );
    open my $ifh, '<', $tmpfile
      or die "Cannot open temp file '$tmpfile' for reading: $!";
    binmode($ifh);
    while( my $line = <$ifh> )
    {
      $hook_ref->(
        Apache2::ASP::Test::UploadObject->new(
          filename        => $filename,
          upload_filename => $filename
        ),
        $line
      );
    }# end while()
    
    # One more *without* any data (this will signify and EOF condition):
    $hook_ref->(
      Apache2::ASP::Test::UploadObject->new(
        filename        =>  $filename,
        upload_filename => $filename
      ),
      undef
    );
  }# end foreach()
  
  # NOW we can execute...
  return $s->_setup_response( $s->context->execute() );
}# end upload()


#==============================================================================
sub submit_form
{
  my ($s, $form) = @_;
  
  no strict 'refs';
  undef(${"$ContextClass\::instance"});
  my $req = $form->click;
  
  %ENV = ( );
  $ENV{REQUEST_METHOD} = uc( $req->method );
  my $cgi = $s->_setup_cgi( $req );
  $ENV{CONTENT_TYPE} = $form->enctype ? $form->enctype : 'application/x-www-form-urlencoded';
  
  my $r = Apache2::ASP::Mock::RequestRec->new();
  $r->uri( $req->uri );
  $r->args( $cgi->{querystring} );
  
  $s->context->setup_request( $r, $cgi );
  
  return $s->_setup_response( $s->context->execute() );
}# end submit_form()


#==============================================================================
sub get
{
  my ($s, $uri) = @_;
  
  no strict 'refs';
  undef(${"$ContextClass\::instance"});
  
  my $req = GET $uri;
  %ENV = ( );
  $ENV{REQUEST_METHOD} = 'GET';
  my $cgi = $s->_setup_cgi( $req );
  $ENV{CONTENT_TYPE} = 'application/x-www-form-urlencoded';
  
  my $r = Apache2::ASP::Mock::RequestRec->new();
  $r->uri( $uri );
  $r->args( $cgi->{querystring} );
  
  $s->context->setup_request( $r, $cgi );
  
  return $s->_setup_response( $s->context->execute() );
}# end get()


#==============================================================================
sub add_cookie
{
  my ($s, $name, $value) = @_;
  
  $s->{cookies}->{$name} = $value;
}# end add_cookie()


#==============================================================================
sub _setup_response
{
  my ($s, $response_code) = @_;
  
  $response_code = 200 if $response_code == 0;
  my $response = HTTP::Response->new( $response_code );
  $response->content( $s->context->r->buffer );
  
  $response->header( 'Content-Type' => $s->context->response->{ContentType} );
  
  foreach my $header ( $s->context->response->Headers )
  {
    while( my ($k,$v) = each(%$header) )
    {
      $response->header( $k => $v );
    }# end while()
  }# end foreach()
  
  if( $s->context->session && $s->context->session->{SessionID} )
  {
    $s->add_cookie(
      $s->context->config->data_connections->session->cookie_name => $s->context->session->{SessionID}
    );
  }# end if()
  
  return $response;
}# end _setup_response()


#==============================================================================
sub _setup_cgi
{
  my ($s, $req) = @_;
  
  $s->{c}->DESTROY
    if $s->{c};
  $req->referer( $s->{referer} || '' );
  ($s->{referer}) = $req->uri =~ m/.*?(\/[^\?]+)/;

  no warnings 'redefine';
  *HTTP::Request::AsCGI::stdout = sub { 0 };
  
  $s->{c} = HTTP::Request::AsCGI->new($req)->setup;
  $ENV{SERVER_NAME} = $ENV{HTTP_HOST} = 'localhost';
  
  unless( $req->uri =~ m@^/handlers@ )
  {
    my ($uri_no_args) = split /\?/, $req->uri;
    $ENV{SCRIPT_FILENAME} = $s->context->config->web->www_root . $uri_no_args;
    $ENV{SCRIPT_NAME} = $uri_no_args;
  }# end unless()
  
  # User-Agent:
  $req->header( 'User-Agent' => 'test-useragent v1.0' );
  $ENV{HTTP_USER_AGENT} = 'test-useragent v1.0';
  
  # Cookies:
  my @cookies = ();
  while( my ($name,$val) = each(%{ $s->{cookies} } ) )
  {
    push @cookies, "$name=" . Apache2::ASP::SimpleCGI->escape($val);
  }# end while()
  
  $req->header( 'Cookie' => join ';', @cookies ) if @cookies;
  $ENV{HTTP_COOKIE} = join ';', @cookies;
  
  if( $ENV{REQUEST_METHOD} =~ m/^post$/i )
  {
    my $body = HTTP::Body->new(
      $req->headers->{'content-type'},
      $req->headers->{'content-length'}
    );
    $body->add( $req->content );
    
    # Set up the basic params:
    return Apache2::ASP::SimpleCGI->new(
      querystring     => $ENV{QUERY_STRING},
      body            => $req->content,
      content_type    => $req->headers->{'content-type'},
      content_length  => $req->headers->{'content-length'},
    );
  }
  else
  {
    # Simple 'GET' request:
    return Apache2::ASP::SimpleCGI->new( querystring => $ENV{QUERY_STRING} );
  }# end if()
}# end _setup_cgi()

1;# return true:

