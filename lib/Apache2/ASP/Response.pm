
package Apache2::ASP::Response;

use strict;
use warnings 'all';
use HTTP::Date qw( time2iso str2time time2str );
use Carp qw( croak confess );
use HTTP::Headers;
use Scalar::Util 'weaken';

our $MAX_BUFFER_LENGTH = 1024 ** 2;

$SIG{__DIE__} = \&confess;
our $IS_TRAPINCLUDE = 0;

#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  # Just guessing:
  my $s = bless {
    %args,
    _status           => 200,
    _output_buffer    => [ ],
    _do_buffer        => 1,
    _buffer_length    => 0,
    _did_send_headers => 0,
  }, $class;
  
  $s->Expires( $args{_expires} || 0 );
  weaken($s->{context});
  return $s;
}# end new()


#==============================================================================
sub context
{
  Apache2::ASP::HTTPContext->current;
#  $_[0]->{context};
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
  $s->Status( '301 Found' );
  $s->End;
}# end Redirect()


#==============================================================================
sub End
{
  my $s = shift;
  
  $s->Flush;
  # Cancel execution and force the server to stop processing this request.
  my $sock = $s->context->connection->client_socket;
  eval { $sock->close() };
  $s->context->{did_end} = 1;
}# end End()


#==============================================================================
sub Flush
{
  my ($s) = @_;
  
  if( $s->context->{parent} )
  {
    if( $IS_TRAPINCLUDE )
    {
      # Do nothing?
    }
    else
    {
      local $Apache2::ASP::HTTPContext::instance = $s->context->{parent};
      return $s->context->response->Flush;
    }# end if()
  }# end if()
  return unless $s->IsClientConnected;
  $s->_send_headers unless $s->context->did_send_headers;
  
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
  
  if( $s->context->{parent} && ! $IS_TRAPINCLUDE )
  {
    local $Apache2::ASP::HTTPContext::instance = $s->context->{parent};
    $s->context->response->Write( @_ );
  }
  else
  {
    $s->{_buffer_length} += length($_[0]);
    push @{$s->{_output_buffer}}, shift;
    $s->Flush if (! $s->{_do_buffer}) || $s->{_buffer_length} >= $MAX_BUFFER_LENGTH;
  }# end if()
}# end Write()


#==============================================================================
sub Include
{
  my ($s, $path) = @_;
  
  my $ctx = $s->context;
  local $Apache2::ASP::HTTPContext::instance = Apache2::ASP::HTTPContext->new( parent => $ctx );
  
  my $root = $s->context->config->web->www_root;
  $path =~ s@^\Q$root\E@@;
  local $ENV{REQUEST_URI} = $path;
  local $ENV{SCRIPT_FILENAME} = $ctx->server->MapPath( $path );
  local $ENV{SCRIPT_NAME} = $path;
  
  use Apache2::ASP::Mock::RequestRec;
  my $clone_r = Apache2::ASP::Mock::RequestRec->new( );
  $clone_r->uri( $path );
  $s->context->setup_request( $clone_r, $ctx->cgi );
  $s->context->execute();
}# end Include()


#==============================================================================
sub TrapInclude
{
  my ($s, $path) = @_;
  
  my $ctx = $s->context;
  local $Apache2::ASP::HTTPContext::instance = Apache2::ASP::HTTPContext->new( parent => $ctx );
  
  my $root = $s->context->config->web->www_root;
  $path =~ s@^\Q$root\E@@;
  local $ENV{REQUEST_URI} = $path;
  local $ENV{SCRIPT_FILENAME} = $ctx->server->MapPath( $path );
  local $ENV{SCRIPT_NAME} = $path;
  
  use Apache2::ASP::Mock::RequestRec;
  my $clone_r = Apache2::ASP::Mock::RequestRec->new( );
  $clone_r->uri( $path );
  $s->context->setup_request( $clone_r, $ctx->cgi );

  $IS_TRAPINCLUDE = 1;
  $s->context->execute();
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
  
  my ($name, $val) = @_;
  die "Usage: Response.AddCookie(name, value)"
    unless defined($name) && defined($val);
  
  my $cookie = join '=', map { $s->context->r->cgi->escape( $_ ) } ( $name => $val );
  $s->context->headers_out->push_header( 'set-cookie' => $cookie );
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
# XXX: Decouple
sub IsClientConnected
{
  return ! $_[0]->context->connection->aborted;
}# end IsClientConnected()


#==============================================================================
sub _send_headers
{
  my $s = shift;
  
  my ($status) = $s->{_status} =~ m/^(\d+)/;
  
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

