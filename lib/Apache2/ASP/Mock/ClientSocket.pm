
package Apache2::ASP::Mock::ClientSocket;

use strict;
use warnings 'all';
use Scalar::Util 'weaken';


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  my $s = bless \%args, $class;
  
  weaken($s->{connection});
  return $s;
}# end new()


#==============================================================================
sub close
{
  my $s = shift;
  
  $s->{connection}->aborted( 1 );
}# end close()

1;# return true:

