
package Apache2::ASP::Test::UserAgent;

use strict;
use warnings 'all';
use HTTP::Request::Common;
use HTTP::Response;
use HTTP::Request::AsCGI;
use HTTP::Body;
use Apache2::ASP::Test::MockRequest;
#use CGI::Simple ();
use Apache2::ASP::SimpleCGI;
use Apache2::ASP::Base;
use Apache2::ASP::Config;
our $ASP_CLASS = 'Apache2::ASP::Base';

#==============================================================================
sub new
{
  my ($class, $asp) = @_;
  $ENV{HTTP_COOKIE} ||= '';
  my $config = Apache2::ASP::Config->new();
  return bless {
#    asp         => Apache2::ASP::Base->new( $config ),
    config      => $config,
    root_dir    => $config->application_root,
    session_id  => 0,
    cookies     =>  { },
    referer     => '',
  }, $class;
}# end new()


#==============================================================================
sub submit_form
{
  my ($s, $form) = @_;
  
  my $req = $form->click;
  
  $s->{asp} = $main::_ASP::ASP = $ASP_CLASS->new( $s->config );
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
sub asp { $_[0]->{asp} }
sub config { $_[0]->{config} }


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
  $ENV{REQUEST_METHOD} = 'GET';
  $s->{asp} = $main::_ASP::ASP = $ASP_CLASS->new( $s->config );
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
  $ENV{REQUEST_METHOD} = 'POST';
  $ENV{CONTENT_TYPE} = 'application/x-www-form-urlencoded';
  $s->{asp} = $main::_ASP::ASP = $ASP_CLASS->new( $s->config );
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
  $ENV{REQUEST_METHOD} = 'POST';
  $ENV{CONTENT_TYPE} = $req->headers->{'content-type'};
  
  $s->{asp} = $main::_ASP::ASP = $ASP_CLASS->new( $s->config );
  my $cgi = $s->_setup_cgi( $req );
  
  $ENV{CONTENT_TYPE} = 'multipart/form-data';
  my $r = Apache2::ASP::Test::MockRequest->new(
    req => $req,
    cgi => $cgi,
  );
  
  $s->{asp}->setup_request( $r, $cgi );
  
  require Apache2::ASP::UploadHook;
  my $hook_obj = Apache2::ASP::UploadHook->new(
    asp           => $s->{asp},
    handler_class => $s->{asp}->resolve_request_handler( $uri ),
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
        Apache2::ASP::Test::UploadObject->new(filename =>  $filename, upload_filename => $filename),
        $line
      );
    }# end while()
    
    # One more *without* any data:
    $hook_ref->(
      Apache2::ASP::Test::UploadObject->new(filename =>  $filename, upload_filename => $filename),
      undef
    );
  }# end foreach()
  
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
  
  if( $s->{asp}->session && $s->{asp}->session->{SessionID} )
  {
    $s->add_cookie( $s->{asp}->config->session_state->cookie_name => $s->{session_id} );
  }# end if()
  
  return $response;
}# end _setup_response()


#==============================================================================
sub _setup_cgi
{
  my ($s, $req) = @_;
  
  # Preserve our session cookie:
  $s->{c}->DESTROY
    if $s->{c};
  $req->referer( $s->{referer} );
  ($s->{referer}) = $req->uri =~ m/.*?(\/[^\?]+)/;

  no warnings 'redefine';
  *HTTP::Request::AsCGI::stdout = sub { 0 };
  $s->{c} = HTTP::Request::AsCGI->new($req)->setup;
  $ENV{SERVER_NAME} = $ENV{HTTP_HOST} = 'localhost';
  $ENV{APACHE2_ASP_APPLICATION_ROOT} = $s->{root_dir};
  
  unless( $req->uri =~ m@^/handlers@ )
  {
    $ENV{SCRIPT_FILENAME} = $s->{asp}->config->www_root . $req->uri;
  }# end unless()
  
  # User-Agent:
  $req->header( 'User-Agent' => 'apache2-asp-test-useragent v1.0' );
  
  # Cookies:
  my @cookies = ();
  while( my ($name,$val) = each(%{ $s->{cookies} } ) )
  {
    push @cookies, "$name=" . Apache2::ASP::SimpleCGI->escape($val);
  }# end while()
  $req->header( 'Cookie' => join ';', @cookies );
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

=head1 IMPORTANT BUG

After creating an instance of C<Apache2::ASP::Test::UserAgent> you cannot print to C<STDOUT>.

B<However> you can C<warn> just fine.

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

Please visit the Apache2::ASP homepage at L<http://www.devstack.com/> to see examples
of Apache2::ASP in action.

=head1 AUTHOR

John Drago L<mailto:jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut
