
package Apache2::ASP::Mock::Pool;

use strict;
use warnings 'all';


#==============================================================================
sub new
{
  return bless {_cleanup_handlers => [ ]}, shift;
}# end new()


#==============================================================================
sub cleanup_register
{
  my ($s, $ref, $args) = @_;
  
  push @{$s->{_cleanup_handlers}}, sub { $ref->( $args ) };
}# end cleanup_register()


#==============================================================================
sub DESTROY
{
  my $s = shift;
  
  map { $_->() } @{$s->{_cleanup_handlers}};
}# end DESTROY()

1;# return true:

