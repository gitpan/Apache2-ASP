
package Apache2::ASP::CGI;

use strict;
use warnings;
use base 'CGI::Apache2::Wrapper';

#==============================================================================
sub new
{
  my ($class, $r, $upload_hook) = @_;
  
  # Default to 100Mb uploads:
  my %options = ();
  if( $ENV{APACHE2_ASP_MAX_UPLOAD} )
  {
    $options{POST_MAX} = $ENV{APACHE2_ASP_MAX_UPLOAD};
  }# end if()
  
  my $s = $class->SUPER::new( $r );
  if( ref($upload_hook) eq 'CODE' )
  {
    my $req = Apache2::Request->new(
      $r,
      UPLOAD_HOOK => $upload_hook,
    );
    $s->req(
      $req
    );
# This causes the logs to warn of "Conflicting data":
#    $s->req->read_limit( $ENV{CONTENT_LENGTH} );
  }
  else
  {
    $s->req(Apache2::Request->new($r));
  }# end if()
  
  return $s;
}# end new()

1;# return true:

