
package Apache2::ASP::CGI;

our $VERSION = 0.08;

use strict;
use warnings;
use base 'CGI::Apache2::Wrapper';

sub new
{
  my ($class, $r, $upload_hook) = @_;
  
  my $s = $class->SUPER::new( $r );
  if( ref($upload_hook) eq 'CODE' )
  {
    $s->req(
      Apache2::Request->new(
        $r,
        UPLOAD_HOOK => $upload_hook,
      )
    );
  }
  else
  {
    $s->req(Apache2::Request->new($r));
  }# end if()
  
  return $s;
}# end new()

1;# return true:

