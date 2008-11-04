

package Apache2::ASP::TransHandler;

use strict;
use APR::Table ();
use Apache2::RequestRec ();
use Apache2::RequestUtil ();
use Apache2::SubRequest ();
use Apache2::Const -compile => ':common';
use Apache2::ServerRec ();


#==============================================================================
sub handler : method
{
  my ($class, $r) = @_;
  
  $ENV{DOCUMENT_ROOT} ||= $r->document_root;
  
  return -1;
}# end handler()

1;# return true:

