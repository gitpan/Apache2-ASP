
package Apache2::ASP::MockRequest;

our $VERSION = 0.07;

use strict;
use warnings;


#==============================================================================
sub new
{
  my ($s, %args) = @_;
  return bless {%args, _buffer => ''}, ref($s) || $s;
}# end new()


#==============================================================================
sub print
{
  my ($s, $str) = @_;
  
  $s->{_buffer} .= $str;
}# end print()


#==============================================================================
sub AUTOLOAD
{
  return shift;
}# end AUTOLOAD()

1;# return true:
