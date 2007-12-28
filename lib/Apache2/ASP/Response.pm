
package Apache2::ASP::Response;

use strict;
use warnings 'all';
use Apache2::Const "-compile" => ':common';
use HTTP::Date qw( time2iso str2time time2str );
#use HTML::FillInForm;

use Apache2::ASP::ApacheRequest;

our $MAX_BUFFER_LENGTH = 1024 ** 2;


#==============================================================================
sub new
{
  my ($s, $asp) = @_;
  
  return bless {
    asp            => $asp,
    _buffer         => '',
    r               => $asp->r,
    q               => $asp->q,
    _headers        => [ {name => 'connection', value => 'close'} ],
    _sent_headers   => 0,
    Buffer          => 1,
    ContentType     => 'text/html',
    Status          => 200,
    ApacheStatus    => Apache2::Const::OK,
    Expires         => 0,
    ExpiresAbsolute => time2str(time),
  }, $s;
}# end new()


#==============================================================================
sub Buffer
{
  my $s = shift;
  if( @_ )
  {
    return $s->{Buffer} = shift;
  }
  else
  {
    return $s->{Buffer};
  }# end if()
}# end Buffer()


#==============================================================================
sub Expires
{
  my $s = shift;
  if( @_ )
  {
    $s->{Expires} = shift;
    $s->ExpiresAbsolute( time2str( time() + $s->{Expires} ) );
    return $s->{Expires};
  }
  else
  {
    return $s->{Expires};
  }# end if()
}# end Expires()


#==============================================================================
sub ExpiresAbsolute
{
  my $s = shift;
  if( @_ )
  {
    return $s->{ExpiresAbsolute} = shift;
  }
  else
  {
    return $s->{ExpiresAbsolute};
  }# end if()
}# end Expires()


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
sub Headers
{
  my $s = shift;
  
  return {
    map {
      $_->{name} => $_->{value}
    } @{$s->{_headers}}
  };
}# end Headers()


#==============================================================================
sub Cookies
{
  my ($s, $name, $value) = @_;
  
  no warnings 'uninitialized';
  my $escape = $s->{q}->can('escape') ? sub { $s->{q}->escape(@_) } : sub { $s->{q}->url_encode(@_) };
  return $s->AddHeader( "Set-Cookie" => "$name=" . $escape->("$value") );
}# end Cookies()


#==============================================================================
sub Write
{
  my ($s, $str) = @_;
  
  $str = "" unless defined($str);
  $str =~ s/_____TILDE_____/\~/g;
  
  no warnings 'uninitialized';
  $s->{_buffer} .= $str;
  if( $s->{Buffer} )
  {
    if( length($s->{_buffer}) >= $MAX_BUFFER_LENGTH )
    {
      $s->Flush;
    }# end if()
  }
  else
  {
    $s->Flush;
  }# end if()
}# end Write()


#==============================================================================
sub Flush
{
  my $s = shift;
  
  my $buffer = delete( $s->{_buffer} );

  if( $s->{asp}->{handler} && $s->{asp}->{handler}->isa('Apache2::ASP::PageHandler') && $s->{asp}->global_asa )
  {
#    if( defined($buffer) && length($buffer) )
#    {
#      my $fif = HTML::FillInForm->new();
#      $buffer .= "\n";
#      $buffer = $fif->fill(
#        scalarref => \$buffer,
#        fdat      => $s->{asp}->session->{__lastArgs} || { }
#      );
#      no warnings 'uninitialized';
#      $buffer =~ s/\n$//;
#    }# end if()
#    
    $s->{asp}->global_asa->can('Script_OnFlush')->( \$buffer )
      unless $s->{is_subrequest};
  }# end if()
  
  $s->_print_headers();
  
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
  my $sock = $s->{r}->connection->client_socket;
  eval { $sock->close() };
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
  
  if( $s->{_sent_headers} )
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
  my ($s, $script, @args) = @_;
  
  -f $script or die "Cannot Response.Include '$script': File not found";
  
  my $uri = $script;
  my $root = $s->{asp}->config->www_root;
  $uri =~ s/^$root//;
  my $r = Apache2::ASP::ApacheRequest->new(
    r => $s->{asp}->r,
    status => '200 OK',
    filename => $script,
    uri      => $uri
  );
  my $asp = ref($s->{asp})->new( $s->{asp}->config );
  $asp->{ $_ } = $s->{asp}->{ $_ }
    foreach grep { exists($s->{asp}->{$_}) }
      qw/
        session
        application
        service
        subservice
        registry_member
      /;
  $asp->setup_request( $r, $s->{asp}->q );
  eval {
    $asp->execute( 1, @args );
    $s->Write( $r->buffer );
#    $s->Flush;
  };
  if( $@ )
  {
    die "Cannot Include script '$script': $@";
  }# end if()
}# end Include()


#==============================================================================
sub TrapInclude
{
  my ($s, $script, @args) = @_;
  
  -f $script or die "Cannot Response.TrapInclude '$script': File not found";
  
  my $uri = $script;
  my $root = $s->{asp}->config->www_root;
  $uri =~ s/^$root//;
  my $r = Apache2::ASP::ApacheRequest->new(
    r => $s->{asp}->r,
    status => '200 OK',
    filename => $script,
    uri      => $uri
  );
  my $asp = ref($s->{asp})->new( $s->{asp}->config );
  $asp->{ $_ } = $s->{asp}->{ $_ }
    foreach grep { exists($s->{asp}->{$_}) }
      qw/
        session
        application
        service
        subservice
        registry_member
      /;
  $asp->setup_request( $r, $s->{asp}->q );
  
  my $include = eval {
    $asp->execute( 1, @args );
    $asp->response->End;
    return $r->buffer;
  };
  if( $@ )
  {
    die "Cannot TrapInclude script '$script': $@";
  }# end if()
  
  return $include;
}# end Include()


#==============================================================================
sub IsClientConnected
{
  my $s = shift;
  return ! $s->{r}->connection->aborted;
}# end IsClientConnected()


#==============================================================================
sub _print_headers
{
  my $s = shift;
  
  return if $s->{_sent_headers};
  
  $s->{r}->content_type( $s->{ContentType} || 'text/html' );
  my ($status) = $s->{Status} =~ m/^(\d+)/;
  $s->{r}->status( $status );
  
  my $headers = $s->{r}->headers_out;
  foreach my $header ( @{$s->{_headers}} )
  {
    $headers->{ $header->{name} } = $header->{value};
  }# end foreach()
  $headers->{Expires} = $s->{ExpiresAbsolute};
  
  $s->{r}->headers_out( $headers );
  
  $s->{_sent_headers} = 1;
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

=head2 new( $asp )

=head2 AddHeader( $name, $value )

Adds a new header to the HTTP response

For example, the following:

  <%
    $Response->AddHeader( "funny-factor" => "funny" );
  %>

Sends the following in the HTTP response:

  funny-factor: funny

=head2 Headers( )

Returns a name/value hash of all the HTTP headers that have been set via C<AddHeader>.

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

=head2 Expires( [$minutes] )

Set/get the number of minutes between now and when the content will expire.

Negative values are permitted.

Default is C<0>.

=head2 ExpiresAbsolute( [$http_datetime] )

Set/get the date in HTTP date format when the content will expire.

Default is now.

=head2 Buffer( [$bool] )

Gets/sets the buffering behavior.  Default value is C<1>.

  # Turn off buffering, forcing output to be flushed to the client immediately:
  $Response->Buffer(0);
  
  # Turn on buffering.  Wait until the request is finished before the buffer is sent:
  $Response->Buffer(1);

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

