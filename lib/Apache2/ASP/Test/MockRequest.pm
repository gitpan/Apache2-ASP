
package Apache2::ASP::Test::MockRequest;

use strict;
use warnings 'all';
use Cwd 'cwd';


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  
  foreach(qw/ req cgi /)
  {
    die "Required parameter '$_' was not provided"
      unless defined($args{$_});
  }# end foreach()
  
  %args = (
    buffer        => '',
    status        => 200,
    _headers_out  => { },
    _headers_in   => { },
    rflush        => 1,
    %args
  );
  
  return bless \%args, $class;
}# end new()


#==============================================================================
sub args
{
  my ($s) = @_;
  
  my (undef,$args) = split /\?/, $s->{req}->uri;
  return $args;
}# end args()


#==============================================================================
sub uri
{
  my ($s) = @_;
  
  my ($uri) = split /\?/, $s->{req}->uri;
  return $uri;
}# end uri()


#==============================================================================
sub print
{
  my ($s, $str) = @_;
  no warnings 'uninitialized';
  $s->{buffer} .= $str;
}# end print()


#==============================================================================
sub buffer
{
  my $s = shift;
  return $s->{buffer};
}# end buffer()


#==============================================================================
sub lookup_uri
{
  my ($s, $path) = @_;
  
  return if $s->{disable_lookup_uri};
  
  my $here = cwd();
  return ref($s)->new(
    cgi         => $s->{cgi},
    req         => $s->{req},
    filename    => $here . $path,
  );
}# end lookup_uri()


#==============================================================================
sub headers_out
{
  my ($s, $arg) = @_;
  return $s->{_headers_out} unless $arg;
  $s->{_headers_out} = $arg;
}# end headers_out()


#==============================================================================
sub connection
{
  my ($s) = @_;
  
  return ref($s)->new(
    client_socket => ref($s)->new(
      close => 1,
      cgi         => $s->{cgi},
      req         => $s->{req},
    ),
    cgi         => $s->{cgi},
    req         => $s->{req},
      aborted     => 0,
  );
}# end connection()


#==============================================================================
sub unescape
{
  my $s = shift;
  $s->{cgi}->url_decode( @_ );
}# end unescape()


#==============================================================================
sub escape
{
  my $s = shift;
  $s->{cgi}->url_encode( @_ );
}# end escape()


#==============================================================================
sub AUTOLOAD
{
  my $s = shift;
  our $AUTOLOAD;
  my ($method) = $AUTOLOAD =~ m/::([^:]+)$/;
  
  # If we can't handle the request, try passing it on to our request:
  if( ! exists( $s->{$method} ) )
  {
    no warnings 'uninitialized';
    if( $s->{cgi}->can($method) )
    {
      return $s->{cgi}->$method( @_ );
    }
    elsif( $s->{req}->can($method) )
    {
      return $s->{req}->$method( @_ );
    }
    else
    {
      die "Unhandled method '$method'";
    }# end if()
  }# end if()
  
  # Are we in 'setter' or 'getter' mode?
  if( @_ )
  {
    # Setter:
    return $s->{$method} = shift;
  }
  else
  {
    # Getter:
    return $s->{$method};
  }# end if()
}# end AUTOLOAD()

sub DESTROY { }

1;# return true:
