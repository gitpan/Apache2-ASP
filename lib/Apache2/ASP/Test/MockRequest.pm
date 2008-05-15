
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
    content_type  => 'text/html',
    _headers_out  => { },
    _headers_in   => { },
    rflush        => 1,
    push_handlers => 1,
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
  my ($s) = shift;
  
  if( @_ )
  {
    $s->{req}->uri( shift(@_) );
  }
  else
  {
    my ($uri) = split /\?/, $s->{req}->uri;
    return $uri;
  }# end if()
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
sub filename
{
  my ($s) = @_;
  
  return if $s->{disable_lookup_uri};
  my $here = cwd();
  return $here . $s->uri;
}# end filename()


#==============================================================================
sub pool
{
  return bless { cleanup_register => 1 }, ref(shift);
}# end pool()


#==============================================================================
sub lookup_uri
{
  my ($s, $path) = @_;
  
  return if $s->{disable_lookup_uri};
  
  my $here = cwd();
  no warnings 'uninitialized';
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
  $s->{cgi}->unescape( @_ );
}# end unescape()


#==============================================================================
sub escape
{
  my $s = shift;
  $s->{cgi}->escape( @_ );
}# end escape()


#==============================================================================
sub pnotes
{
  my ($s) = shift;
  if( @_ == 1 )
  {
    my $key = shift;
    return $s->{_pnotes}->{$key} if exists($s->{_pnotes}->{$key});
  }
  elsif( @_ == 2 )
  {
    my ($key, $val) = @_;
    return $s->{_pnotes}->{$key} = $val;
  }# end if()
}# end pnotes()


#==============================================================================
sub AUTOLOAD
{
  my $s = shift;
  our $AUTOLOAD;
  my ($method) = $AUTOLOAD =~ m/::([^:]+)$/;
  
  # If we can't handle the request, try passing it on to our request:
  if( exists( $s->{$method} ) )
  {
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
  }
  else
  {
    no warnings 'uninitialized';
    if( $s->{cgi} && $s->{cgi}->can($method) )
    {
      return $s->{cgi}->$method( @_ );
    }
    elsif( $s->{req}->can($method) )
    {
      return $s->{req}->$method( @_ );
    }
    else
    {
      die "Unhandled method '$method' called from " . join( ' at ', caller);
    }# end if()
  }# end if()
  
}# end AUTOLOAD()

sub DESTROY { }

1;# return true:
