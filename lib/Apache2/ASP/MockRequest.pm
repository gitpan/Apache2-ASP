

package Apache2::ASP::MockRequest;
# Used for TrapInclude:

use strict;
use warnings;

our $VERSION = 0.06;

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
