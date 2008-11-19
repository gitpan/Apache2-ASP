
package Apache2::ASP::ConfigNode::System;

use strict;
use warnings 'all';
use base 'Apache2::ASP::ConfigNode';
use Apache2::ASP::ConfigNode::System::Settings;


#==============================================================================
sub new
{
  my $class = shift;
  
  my $s = $class->SUPER::new( @_ );
  $s->{settings} = Apache2::ASP::ConfigNode::System::Settings->new( $s->{settings} );
  
  return $s;
}# end new()


#==============================================================================
sub libs
{
  my $s = shift;
  
  @{ $s->{libs}->{lib} };
}# end libs()

#==============================================================================
sub load_modules
{
  my $s = shift;
  
  @{ $s->{load_modules}->{module} };
}# end libs()

#==============================================================================
sub env_vars
{
  my $s = shift;
  
  @{ $s->{env_vars}->{var} };
}# end libs()

#==============================================================================
sub post_processors
{
  my $s = shift;
  
  @{ $s->{post_processors}->{class} };
}# end libs()


#==============================================================================
sub settings
{
  my $s = shift;
  
  return wantarray ? @{ $s->{settings}->{setting} } : $s->{settings};
}# end settings()

1;# return true:

