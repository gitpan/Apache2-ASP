
package My::MemberFilter;

use strict;
use warnings 'all';
use base 'Apache2::ASP::RequestFilter';
use vars qw(
  $Request  $Application
  $Response $Server
  $Session  $Form
  $Config
);

#==============================================================================
sub run
{
  my ($s) = @_;
  
  if( $Session->{logged_in} )
  {
    return $Response->Declined;
  }
  else
  {
    my $url = $Server->URLEncode( $ENV{REQUEST_URI} );
    return $Response->Redirect("/login.asp?return_url=$url");
  }# end if()
}# end run()

1;# return true:
