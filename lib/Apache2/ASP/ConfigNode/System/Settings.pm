
package Apache2::ASP::ConfigNode::System::Settings;

use strict;
use warnings 'all';
use base 'Apache2::ASP::ConfigNode';


#==============================================================================
sub new
{
  my $class = shift;
  
  my $s = $class->SUPER::new( @_ );
  
  return $s;
}# end new()


#==============================================================================
sub AUTOLOAD
{
  my $s = shift;
  our $AUTOLOAD;
  
  my ($name) = $AUTOLOAD =~ m/([^:]+)$/;
  
  my ($val) = grep {
    $_->{name} eq $name
  } @{ $s->{setting} };
  
  defined($val) or return;
  return $val->{value};
}# end AUTOLOAD()

1;# return true:

