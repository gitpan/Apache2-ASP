
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
  
  if( $req->uri =~ m/^\/handlers/ )
  {
#    $ENV{SCRIPT_FILENAME} = 
  }
  else
  {
    $ENV{SCRIPT_FILENAME} = $s->{asp}->config->www_root . $req->uri;
  }# endif()
  
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

=head1 NAME

Apache2::ASP::Test::UserAgent - User-agent for testing Apache2::ASP web applications

=head1 SYNOPOSIS

  use Apache2::ASP::Test::UserAgent;
  
  my $ua = Apache2::ASP::Test::UserAgent->new( $asp );
  
  my $response = $ua->get( '/index.asp' );
  
  my $response = $ua->post( '/handlers/FormHandler', [
    username  => 'admin',
    password  => 's3cr3t',
  ]);
  
  my $response = $ua->upload( '/handlers/UploadHandler', [
    title     => 'this is my file',
    filename  => ['/path/to/file.txt']
  ]);
  
  # $response is a regular HTTP::Response object, so...:
  if( $response->is_success )
  {
    # Everything worked out OK.
  }
  else
  {
    # Request failed.
  }# end if()
  
  # Deal with forms:
  use HTML::Form;
  my $response = $ua->get( '/some-form.asp' );
  my $form = HTML::Form->parse( $response->content, '/some-form.asp' );
  $form->find_input( 'username' )->value( 'admin' );
  $form->find_input( 'password' )->value( 's3cr3t' );
  my $after_response = $ua->submit_form( $form );

=head1 DESCRIPTION

C<Apache2::ASP::Test::UserAgent> offers the ability to test your web applications without requiring
a running Apache webserver or direct human interaction.

Simply by using L<Devel::Cover> you can easily generate code-coverage reports on your ASP scripts.  
Such coverage reports can be used to tell you what code is executed during your tests.

=head1 PUBLIC PROPERTIES

=head1 asp

Returns the L<Apache2::ASP> object currently in use by the C<Apache2::ASP::Test::UserAgent> object.

=head1 PUBLIC METHODS

=head2 new( $asp )

Constructor.  The C<$asp> argument should be an C<Apache2::ASP::Base> object.

Returns a new C<Apache2::ASP::Test::UserAgent> object.

=head2 add_cookie( $name, $value )

Appends a cookie to be sent on all future requests.

=head2 get( $url )

Makes a C<GET> request to C<$url> via L<Apache2::ASP::Base>.

Content-encoding is C<application/x-www-form-urlencoded>.

Returns an L<HTTP::Response> object.

=head2 post( $url, $content )

Makes a C<POST> request to C<$url> via L<Apache2::ASP::Base>, sending C<$content> as its request data.

Content-encoding is C<application/x-www-form-urlencoded>.

Returns an L<HTTP::Response> object.

=head2 upload( $url, $content )

Makes a C<POST> request to C<$url> via L<Apache2::ASP::Base>, sending C<$content> as its request data.

Content-encoding is C<multipart/form-data>.

Returns an L<HTTP::Response> object.

=head2 submit_form( $form )

C<$form> should be a valid C<HTML::Form> object.  The C<$form> is submitted via its C<click()> method, 
and the resulting L<HTTP::Request> object is processed.

Returns a L<HTTP::Response> object.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-ASP> to submit bug reports.

=head1 HOMEPAGE

Please visit the Apache2::ASP homepage at L<http://apache2-asp.no-ip.org/> to see examples
of Apache2::ASP in action.

=head1 AUTHOR

John Drago L<mailto:jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut