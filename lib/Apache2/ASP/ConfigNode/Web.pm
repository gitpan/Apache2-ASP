
package Apache2::ASP::ConfigNode::Web;

use strict;
use warnings 'all';
use base 'Apache2::ASP::ConfigNode';


#==============================================================================
sub new
{
  my $class = shift;
  
  my $s = $class->SUPER::new( @_ );
  
  map {
    $_->{uri_match} = undef unless defined($_->{uri_match});
    $_->{uri_equals} = undef unless defined($_->{uri_equals});
    $_ = $class->SUPER::new( $_ );
  } $s->request_filters;
  return $s;
}# end new()


#==============================================================================
sub request_filters
{
  my $s = shift;
  
  @{ $s->{request_filters}->{filter} };
}# end request_filters()

1;# return true:

