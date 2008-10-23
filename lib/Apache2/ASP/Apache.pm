
package Apache2::ASP::Apache;

use strict;
use warnings 'all';
use APR::Table ();
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Directive ();
use Apache2::Connection ();
use Apache2::SubRequest ();
use Apache2::RequestUtil ();
use Apache2::ASP::HTTPContext ();
use Apache2::ASP::ModPerl2CGI ();

sub handler : method
{
  my ($class, $r) = @_;
  
  my $context = $Apache2::ASP::HTTPContext::ClassName->new( );
  my $cgi = Apache2::ASP::ModPerl2CGI->new( $r );
  $context->setup_request( $r, $cgi );
  return $context->execute;
}# end handler()

1;# return true:

