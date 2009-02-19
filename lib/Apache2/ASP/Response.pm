
package Apache2::ASP::Response;

use strict;
use warnings 'all';
use HTTP::Date qw( time2iso str2time time2str );
use Carp qw( croak confess );
use HTTP::Headers;
#use Scalar::Util 'weaken';
use Apache2::ASP::Mock::RequestRec;

our $MAX_BUFFER_LENGTH = 1024 ** 2;

#$SIG{__DIE__} = \&confess;
our $IS_TRAPINCLUDE = 0;

#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  delete($args{context});
  # Just guessing:
  my $s = bless {
#    %args,
    _status           => 200,
    _output_buffer    => [ ],
    _do_buffer        => 1,
    _buffer_length    => 0,
    _did_send_headers => 0,
  }, $class;
  $s->ContentType('text/html');
  
  $s->Expires( $args{_expires} || 0 );
  return $s;
}# end new()


#==============================================================================
sub context
{
  Apache2::ASP::HTTPContext->current;
}# end context()


#==============================================================================
sub ContentType
{
  my $s = shift;
  
  if( @_ )
  {
    confess "Response.ContentType cannot be changed after headers have been sent"
      if $s->{_did_send_headers};
    $s->context->content_type( shift );
  }
  else
  {
   return $s->context->content_type;
  }# end if()
}# end ContentType()


#==============================================================================
sub Status
{
  my $s = shift;
  
  if( @_ )
  {
    confess "Response.Status cannot be changed after headers have been sent"
      if $s->{_did_send_headers};
    
    $s->{_status} = shift;
  }
  else
  {
    return $s->{_status};
  }# end if()
}# end Status()


#==============================================================================
sub Expires
{
  my $s = shift;
  
  if( @_ )
  {
    # Setter:
    $s->{_expires} = shift;
    $s->ExpiresAbsolute( time2str(time + $s->{_expires} * 60 ) );
  }
  else
  {
    # Getter:
    return $s->{_expires};
  }# end if()
}# end Expires()


#==============================================================================
sub ExpiresAbsolute
{
  my $s = shift;
  if( my $when = shift )
  {
    $s->DeleteHeader('expires');
    $s->{_expires_absolute} = $when;
#    $s->AddHeader( expires => shift );
  }
  else
  {
    return $s->{_expires_absolute};
  }# end if()
}# end ExpiresAbsolute()


#==============================================================================
sub Declined
{
  return -1;
}# end Declined()


#==============================================================================
sub Redirect
{
  my ($s, $url) = @_;
  
  confess "Response.Redirect cannot be called after headers have been sent"
    if $s->{_did_send_headers};
  
  $s->Clear;
  $s->AddHeader( location => $url );
  $s->Status( 302 );
  $s->End;
}# end Redirect()


#==============================================================================
sub End
{
  my $s = shift;
  
  $s->Flush;
  # Cancel execution and force the server to stop processing this request.
#  my $sock = $s->context->connection->client_socket;
#  $sock->close();
#  eval { $sock->close() };
  $s->context->set_prop( did_end => 1 );
}# end End()


#==============================================================================
sub Flush
{
  my ($s) = @_;
  
  if( $s->context->{parent} )
  {
    if( $IS_TRAPINCLUDE )
    {
      # Do nothing:
      # We are not flushing - we are doing a Response.TrapInclude(...)
    }
    else
    {
    no strict 'refs';
    my $parent = $s->context->{parent};
    local ${"$Apache2::ASP::HTTPContext::ClassName\::instance"} = $s->context->{parent};
      return $s->context->response->Flush;
    }# end if()
  }# end if()
  return unless $s->IsClientConnected;
  $s->_send_headers unless $s->context->did_send_headers;
  
  no warnings 'uninitialized';
  $s->context->print( join '', @{delete($s->{_output_buffer})} );
  $s->context->rflush;
  $s->{_output_buffer} = [ ];
  $s->{_buffer_length} = 0;
}# end Flush()


#==============================================================================
our $WRITES = 0;
sub Write
{
  my $s = shift;
  my $ctx = $s->context;
  return if $ctx->{did_end};
  
  if( $ctx->{parent} && ! $IS_TRAPINCLUDE )
  {
    no strict 'refs';
    my $parent = $ctx->{parent};
    local ${"$Apache2::ASP::HTTPContext::ClassName\::instance"} = $ctx->{parent};
    $ctx->response->Write( @_ );
  }
  else
  {
    no warnings 'uninitialized';
    $s->{_buffer_length} += length($_[0]);
    push @{$s->{_output_buffer}}, shift;
    $s->Flush if (! $s->{_do_buffer}) || $s->{_buffer_length} >= $MAX_BUFFER_LENGTH;
  }# end if()
}# end Write()


#==============================================================================
sub Include
{
  my ($s, $path, $args) = @_;
  return if $s->context->{did_end};
  
  my $ctx = $s->context;
  no strict 'refs';
  local ${"$Apache2::ASP::HTTPContext::ClassName\::instance"} = $Apache2::ASP::HTTPContext::ClassName->new( parent => $ctx );
  
  my $root = $s->context->config->web->www_root;
  $path =~ s@^\Q$root\E@@;
  local $ENV{REQUEST_URI} = $path;
  local $ENV{SCRIPT_FILENAME} = $ctx->server->MapPath( $path );
  local $ENV{SCRIPT_NAME} = $path;
  
  use Apache2::ASP::Mock::RequestRec;
  my $clone_r = Apache2::ASP::Mock::RequestRec->new( );
  $clone_r->uri( $path );
  $s->context->setup_request( $clone_r, $ctx->cgi );
  my $res = $s->context->execute( $args );
  if( $res > 200 )
  {
    $s->Status( $res );
  }# end if()
}# end Include()


#==============================================================================
sub TrapInclude
{
  my ($s, $path, $args) = @_;
  return if $s->context->{did_end};
  
  my $ctx = $s->context;
  no strict 'refs';
  local ${"$Apache2::ASP::HTTPContext::ClassName\::instance"} = $Apache2::ASP::HTTPContext::ClassName->new( parent => $ctx );
  
  my $root = $s->context->config->web->www_root;
  $path =~ s@^\Q$root\E@@;
  local $ENV{REQUEST_URI} = $path;
  local $ENV{SCRIPT_FILENAME} = $ctx->server->MapPath( $path );
  local $ENV{SCRIPT_NAME} = $path;
  
  my $clone_r = Apache2::ASP::Mock::RequestRec->new( );
  $clone_r->uri( $path );
  $s->context->setup_request( $clone_r, $ctx->cgi );

  $IS_TRAPINCLUDE = 1;
  $s->context->execute( $args );
  $s->context->response->Flush;
  
  $IS_TRAPINCLUDE = 0;
  return $clone_r->{buffer};
}# end TrapInclude()


#==============================================================================
sub Cookies
{
  $_[0]->context->headers_out->{'set-cookie'};
}# end Cookies()


#==============================================================================
sub AddCookie
{
  my $s = shift;
  
  my ($name, $val, $path, $expires) = @_;
  die "Usage: Response.AddCookie(name, value [, path [, expires ]])"
    unless defined($name) && defined($val);
  $path ||= '/';
  $expires ||= time() + ( 60 * 30 );
  my $expire_date ||= time2str( $expires );
  
  my $cookie = join '=', map { $s->context->cgi->escape( $_ ) } ( $name => $val );
  $s->context->headers_out->push_header( 'set-cookie' => "$cookie; path=$path; expires=$expire_date" );
}# end AddCookie()


#==============================================================================
sub AddHeader
{
  my ($s, $name, $val) = @_;
  
  return unless defined($name) && defined($val);
  
  $s->context->headers_out->push_header( $name => $val );
}# end AddHeader()


#==============================================================================
sub DeleteHeader
{
  my ($s, $name) = @_;
  
  $s->context->headers_out->remove_header( $name );
}# end DeleteHeader()


#==============================================================================
sub Headers
{
  $_[0]->context->headers_out;
}# end Headers()


#==============================================================================
sub Clear
{
  $_[0]->{_output_buffer} = [ ];
}# end Clear()


#==============================================================================
sub IsClientConnected
{
  return ! shift->context->get_prop('did_end');
#  return ! $_[0]->context->connection->aborted;
}# end IsClientConnected()


#==============================================================================
sub _send_headers
{
  my $s = shift;
  
  my ($status) = $s->{_status} =~ m/^(\d+)/;
  
  $s->context->r->status( $status );
  $s->context->content_type('text/html') unless $s->context->content_type;
  $s->context->headers_out->push_header( Expires => $s->{_expires_absolute} );
  $s->context->send_headers;
}# end _send_headers()


#==============================================================================
sub DESTROY
{
  my $s = shift;
  
  undef(%$s);
}# end DESTROY()

1;# return true:

=head1 NAME

Apache2::ASP::Response - Outgoing response object.

=head1 SYNOPSIS

  return $Response->Redirect("/another.asp");
  
  return $Response->Declined;
  
  $Response->End;
  
  $Response->ContentType("text/xml");
  
  $Response->Status( 404 );
  
  # Make this response expire 30 minutes ago:
  $Response->Expires( -30 );
  
  $Response->Include( $Server->MapPath("/inc/top.asp"), { foo => 'bar' } );
  
  my $html = $Response->TrapInclude( $Server->MapPath("/inc/top.asp"), { foo => 'bar' } );
  
  $Response->AddHeader("content-disposition: attachment;filename=report.csv");
  
  $Response->Write( "hello, world" );
  
  $Response->Clear;
  
  $Response->Flush;

=head1 DESCRIPTION

Apache2::ASP::Response offers a wrapper around the outgoing response to the client.

=head1 PUBLIC PROPERTIES

=head2 ContentType( [$type] )

Sets/gets the content-type response header (i.e. text/html, image/gif, etc).

Default: text/html

=head2 Status( [$status] )

Sets/gets the status response header (i.e. 200, 404, etc).

Default: 200

=head2 Expires( [$minutes] )

Default 0

=head2 ExpiresAbsolute( [$http_date] )

=head2 Declined( )

Returns C<-1>.

=head2 Cookies( )

Returns all outgoing cookies for this response.

=head2 Headers( )

Returns all outgoing headers for this response.

=head2 IsClientConnected( )

Returns true if the client is still connected, false otherwise.

=head1 PUBLIC METHODS

=head2 Write( $str )

Adds C<$str> to the response buffer.

=head2 Redirect( $path )

Clears the response buffer and sends a 301 redirect to the client.

Throws an exception if headers have already been sent.

=head2 Include( $path, \%args )

Executes the script located at C<$path>, passing along C<\%args>.  Output is
included as part of the current script's output.

=head2 TrapInclude( $path, \%args )

Executes the script located at C<$path>, passing along C<\%args>, and returns
the response as a string.

=head2 AddCookie( $name => $value )

Adds a cookie to the header.

=head2 AddHeader( $name => $value )

Adds a header to the response.

=head2 DeleteHeader( $name )

Removes an outgoing header.

Throws an exception if headers have already been sent.

=head2 Flush( )

Sends any buffered output to the client.

=head2 Clear( )

Clears the outgoing buffer.

=head2 End( )

Closes the connection to the client and terminates the current request.

Throws an exception if headers have already been sent.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-ASP> to submit bug reports.

=head1 HOMEPAGE

Please visit the Apache2::ASP homepage at L<http://www.devstack.com/> to see examples
of Apache2::ASP in action.

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 COPYRIGHT

Copyright 2008 John Drago.  All rights reserved.

=head1 LICENSE

This software is Free software and is licensed under the same terms as perl itself.

=cut

