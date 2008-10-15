
package Apache2::ASP::ConfigNode;

use strict;
use warnings 'all';
use Carp 'confess';


#==============================================================================
sub new
{
  my ($class, $ref) = @_;
  
  my $s = bless $ref, $class;
  $s->init_keys();
  $s;
}# end new()


#==============================================================================
sub init_keys
{
  my $s = shift;
  
  foreach my $key ( grep { ref($s->{$_}) eq 'HASH' } keys(%$s) )
  {
    if( $key eq 'web' )
    {
      require Apache2::ASP::ConfigNode::Web;
      $s->{$key} = Apache2::ASP::ConfigNode::Web->new( $s->{$key} );
    }
    elsif( $key eq 'system' )
    {
      require Apache2::ASP::ConfigNode::System;
      $s->{$key} = Apache2::ASP::ConfigNode::System->new( $s->{$key} );
    }
    else
    {
      $s->{$key} = __PACKAGE__->new( $s->{$key} );
    }# end if()
  }# end foreach()
}# end init_keys()


#==============================================================================
sub AUTOLOAD
{
  my $s = shift;
  our $AUTOLOAD;
  my ($name) = $AUTOLOAD =~ m/([^:]+)$/;
  
  confess "Unknown method or property '$name'" unless exists($s->{$name});
  
  # Setter/Getter:
  @_ ? $s->{$name} = shift : $s->{$name};
}# end AUTOLOAD()


#==============================================================================
sub DESTROY
{
  my $s = shift;
  delete($s->{$_}) foreach keys(%$s);
}# end DESTROY()

1;# return true:

