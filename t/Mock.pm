

package Mock;

use strict;
use warnings 'all';
use CGI ();
use Cwd 'cwd';


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  $ENV{MOD_PERL_API_VERSION} = 2;
  $ENV{MOD_PERL} = 2;
  $args{buffer} = '';
  return bless \%args, $class;
}# end new()


#==============================================================================
sub rflush
{
  1;
}# end rflush()


#==============================================================================
sub print
{
  my ($s, $str) = @_;
  no warnings 'uninitialized';
  $s->{buffer} .= $str;
}# end print()


#==============================================================================
sub uploadInfo
{
  shift;
  {
    'Content-Type'        => 'text/plain',
    'Content-Disposition' => 'attachment',
    type                  => 'text/plain',
  };
}# end uploadInfo()


#==============================================================================
sub upload
{
  my $str = "Hello, World"x800;
  open my $ifh, '<', \$str;
  return $ifh;
}# end upload()


#==============================================================================
sub param
{
  shift;
  my $field = shift;
  
  no warnings 'uninitialized';
  my %form = map { my ($k,$v) = split /\=/, $_ } split /&/, "$ENV{HTTP_QUERYSTRING}";
  if( defined($field) )
  {
    return $form{$field};
  }
  else
  {
    return keys(%form);
  }# end if()
}# end param()


#==============================================================================
sub unescape
{
  shift;
  CGI->unescape( shift );
}# end unescape()


#==============================================================================
sub escape
{
  shift;
  CGI->escape( shift );
}# end escape()


#==============================================================================
sub headers_out
{
  my ($s, $arg) = @_;
  return $s->{headers_out} unless $arg;
  $s->{headers_out} = $arg;
}# end headers_out()


#==============================================================================
sub lookup_uri
{
  my ($s, $path) = @_;
  
  return if $s->{disable_lookup_uri};
  
  my $here = cwd();
  return Mock->new(
    filename  => $here . $path
  );
}# end lookup_uri()


#==============================================================================
sub headers_in
{
  
}


#==============================================================================
# Global getter/setter that dies if an unknown attribute is called on:
sub AUTOLOAD
{
  our $AUTOLOAD;
  my $s = shift;
  my ($method) = $AUTOLOAD =~ m/::([^:]+)$/
    or return;
  if( exists($s->{$method}) )
  {
    if( @_ )
    {
      my $val = shift;
      return $s->{$method} = $val;
    }
    else
    {
      return $s->{$method};
    }# end if()
  }
  else
  {
    die ref($s) . ": unhandled method '$method'";
  }# end if()
}# end AUTOLOAD()

sub DESTROY { }

1;
