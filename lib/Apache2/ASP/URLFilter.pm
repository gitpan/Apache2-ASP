
package Apache2::ASP::URLFilter;

use strict;
use warnings 'all';
use APR::Table ();
use Apache2::RequestRec ();
use Apache2::Const -compile => ':common';

#==============================================================================
sub handler
{
  my ($r) = @_;
  
  return Apache2::Const::DECLINED()
    unless $r->uri =~ m/^\/media\/.+/;
  my ($file) = $r->uri =~ m/^\/media\/([^\?]+)$/;

  my @args = ( "file=$file" );
  if( $r->args )
  {
    push @args, $r->args;
  }# end if()
  
  # Fixup the uri and args:
  $r->uri( '/handlers/MediaManager' );
  $r->args( join '&', @args );
  
  # Send the request on down the line to the next handler:
  return Apache2::Const::DECLINED();
}# end handler()

1;# return true:
