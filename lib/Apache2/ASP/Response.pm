
package Apache2::ASP::Response;

use strict;
use warnings 'all';
use Apache2::Const "-compile" => ':common';
use HTTP::Date qw( time2iso str2time time2str );

our $VERSION = 0.01;

#==============================================================================
sub new
{
  my ($s, $r, $q, $ASP) = @_;
  
  return bless {
    _asp            => $ASP,
    _buffer         => '',
    r               => $r,
    q               => $q,
    _headers        => [ {name => 'connection', value => 'close'} ],
    _sent_header    => 0,
    _sent_status    => 0,
    Buffer          => 1,
    ContentType     => 'text/html',
    Status          => '200 OK',
    ApacheStatus    => Apache2::Const::OK,
    Expires         => 0,
    ExpiresAbsolute => time2str(time),
  }, ref($s) || $s;
}# end new()


#==============================================================================
sub AddHeader
{
  my ($s, $key, $val) = @_;
  push @{$s->{_headers}}, {
    name  => $key,
    value => $val,
  };
}# end AddHeader()


#==============================================================================
sub Cookies
{
  my ($s, $name, $value) = @_;
  
  return $s->AddHeader( $name => $value );
}# end Cookies()


#==============================================================================
sub Write
{
  my ($s, $str) = @_;
  
  no warnings 'uninitialized';
  if( $s->{Buffer} )
  {
    $s->{_buffer} .= $str;
  }
  else
  {
    $s->{r}->print( $str );
  }# end if()
}# end Write()


#==============================================================================
sub Flush
{
  my $s = shift;
  
  my $buffer = delete( $s->{_buffer} );
  $s->{_asp}->{_global_asa}->Script_OnFlush( \$buffer );
  
  if( ! $s->{_sent_header} )
  {
    $s->_print_headers();
  }# end if()
  
  no warnings 'uninitialized';
  $s->{r}->print( $buffer );
  $s->{r}->rflush();
}# end Flush()


#==============================================================================
sub End
{
  my $s = shift;
  $s->Flush;
  # Cancel execution and force the server to stop processing this request.
  $s->{_connection} ||= $s->{r}->connection;
  my $sock = $s->{_connection}->client_socket;
  $sock->close();
}# end End()


#==============================================================================
sub Clear
{
  my $s = shift;
  $s->{_buffer} = '';
}# end Clear()


#==============================================================================
sub Redirect
{
  my ($s, $location) = @_;
  if( $s->{_sent_status} )
  {
    die "Response.Redirect: Cannot redirect after status has been sent.";
  }# end if()
  
  if( $s->{_sent_header} )
  {
    die "Response.Redirect: Cannot redirect after headers have been sent.";
  }# end if()
  
  $s->Clear();
  $s->{ContentType} = '';
  $s->{Status} = '302 Found';
  $s->AddHeader('Location' => $location);
  $s->Flush();
  $s->End;
}# end Redirect()


#==============================================================================
sub Include
{
  # Parse and execute the supplied filename or scalar reference:
  my ($s, $script, @args) = @_;
  
  my $code;
  if( ref($script) )
  {
    $code = $script;
  }
  else
  {
    open my $ifh, '<', $script;
    local $/ = undef;
    my $contents = <$ifh>;
    $code = \$contents;
    close($ifh);
  }# end if()
  $s->{_asp}->execute_script( $code, @args );
}# end Include()


#==============================================================================
sub TrapInclude
{
  # Parse and execute the supplied filename or scalar reference, then return the output:
  my ($s, $script) = @_;
  
  my $code;
  if( ref($script) )
  {
    $code = $$script;
  }
  else
  {
    open my $ifh, '<', $script;
    local $/ = undef;
    my $contents = <$ifh>;
    $code = $contents;
    close($ifh);
  }# end if()
  return $s->{_asp}->handle_sub_request( $code );
}# end TrapInclude()


#==============================================================================
sub IsClientConnected
{
  my $s = shift;
  $s->{_connection} ||= $s->{r}->connection;
  return $s->{_connection}->aborted;
}# end IsClientConnected()


#==============================================================================
sub _set_status
{
  my $s = shift;
  if( $s->{_status} =~ m/200/ )
  {
    $s->{ApacheStatus} = Apache2::Const::OK;
    $s->{r}->status(  );
  }
  elsif( $s->{_status} =~ m/301/ )
  {
    $s->{ApacheStatus} = Apache2::Const::REDIRECT;
  }
  elsif( $s->{_status} =~ m/404/ )
  {
    $s->{ApacheStatus} = Apache2::Const::NOT_FOUND;
  }
  elsif( $s->{_status} =~ m/500/ )
  {
    $s->{ApacheStatus} = Apache2::Const::SERVER_ERROR;
  }
  else
  {
    # Default to 200 OK:
    $s->{ApacheStatus} = Apache2::Const::OK;
  }# end if()
  
  $s->{r}->status( $s->{ApacheStatus} );
  $s->{_sent_status} = 1;
}# end _set_status()


#==============================================================================
sub _print_headers
{
  my $s = shift;
  
  return if $s->{_set_headers};
  
  $s->{r}->content_type( $s->{ContentType} );
  my ($status) = $s->{Status} =~ m/^(\d+)/;
  $s->{r}->status( $status );
  
  my $headers = $s->{r}->headers_out;
  while( my $header = shift @{$s->{_headers}} )
  {
    $headers->{ $header->{name} } = $header->{value};
  }# end while()
  $headers->{Expires} = $s->{ExpiresAbsolute} || time2str(time() + $s->{Expires});
  
  $s->{r}->headers_out( $headers );
  
  $s->{_sent_header} = 1;
  $s->{_sent_status}  = 1;
}# end _print_headers()


#==============================================================================
sub DESTROY
{

}# end DESTROY()


1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::Response - Interact with the client.

=head1 SYNOPSIS

  <%
    # Add a cookie:
    $Response->Cookies( cookiename => "cookie value" );
    
    # Add another HTTP header:
    $Response->AddHeader( 'x-micro-payment-required' => '0.001' );
    
    # Set the content-type header:
    $Response->{ContentType} = 'text/html';
    
    # Set the expiration date to 3 minutes ago:
    $Response->{Expires} = -3;
    
    # Print data to the client:
    $Response->Write("Welcome to the web page.<br>");
    
    # Include another file:
    $Response->Include(
      $Server->MapPath("/my-script.asp"),
      {arg => 'value'}
    );
    
    # Get the output from another file:
    my $result = $Response->TrapInclude(
      $Server->MapPath("/another-script.asp")
    );
    
    # Get a server variable:
    my $host = $Request->ServerVariables("HTTP_HOST");
    
    # Redirect:
    $Response->Redirect( "/new/page.asp" );
    
    # End processing and stop transmission:
    $Response->End;
    
    # Flush data to the client:
    $Response->Flush;
    
    # Clear the buffer:
    $Response->Clear();
    
    # Force auto-flush (no buffering):
    $Response->{Buffer} = 0;
    
    # Do something that takes a long time:
    while( not_done_yet() && $Response->IsClientConnected )
    {
      # do stuff...
    }# end while()
  %>

=head1 DESCRIPTION

The global C<$Response> object is an instance of C<Apache2::ASP::Response>.

=head1 PUBLIC METHODS

=head2 AddHeader( $name, $value )

Adds a new header to the HTTP response

For example, the following:

  <%
    $Response->AddHeader( "funny-factor" => "funny" );
  %>

Sends the following in the HTTP response:

  funny-factor: funny

=head2 Cookies( $name, $value )

Sends a cookie to the client.

=head2 Write( $str )

Writes data to the client.  If buffering is enabled, the output will be 
deferred until C<Flush()> is finally called (automatically or manually).

If buffering is disabled, the output will be sent immediately.

=head2 Flush( )

Causes the response buffer to be printed to the client immediately.

If the HTTP headers have not been sent, they are sent first before the 
response buffer is sent.

=head2 End( )

Stops processing and closes the connection to the client.  The script will
abort right after calling C<End()>.

=head2 Clear( )

Empties the response buffer.  If C<Flush()> has already been called, an exception
is thrown instead.

=head2 Redirect( $url )

Causes the client to be redirected to C<$url>.

If C<Flush()> has already been called, an exception is thrown instead.

=head2 Include( $path, %args )

Executes the script located at C<$path> and passes C<%args> to the script.  The 
result of the included script is included into the current response buffer.

The contents of C<%args> are available to the included script as C<@_>.

=head2 TrapInclude( $path )

Executes the ASP script located at C<$path> and returns its results as a string.

=head2 IsClientConnected( )

Checks to see if the client is still connected.  Returns 1 if connected, 0 if not.

=head1 AUTHOR

John Drago L<jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut
