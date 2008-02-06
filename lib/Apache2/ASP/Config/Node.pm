
package Apache2::ASP::Config::Node;

use strict;
use warnings 'all';

#==============================================================================
sub new
{
  my ($class, %args) = @_;
  return bless \%args, $class;
}# end new()


#==============================================================================
# Discourage the use of public hash notation - use $node->property_name instead:
sub AUTOLOAD
{
  my $s = shift;
  our $AUTOLOAD;
  my ($key) = $AUTOLOAD =~ m/::([^:]+)$/;
  if( exists($s->{ $key }) )
  {
    return $s->{ $key };
  }
  else
  {
    die "Invalid config.node property '$key'";
  }# end if()
}# end AUTOLOAD()


#==============================================================================
sub DESTROY { }

1;# return true:
