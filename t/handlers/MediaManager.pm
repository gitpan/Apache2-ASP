
package MediaManager;

use strict;
use base 'Apache2::ASP::MediaManager';
use vars qw(
  $Request $Form $Response $Server $Session $Application $Config
);

__PACKAGE__->register_mode(
  name    => 'mymode',
  handler => \&do_mymode,
);


#==============================================================================
sub do_mymode
{
  my ($asp) = @_;
  
  $Response->Write("mymode Successful");
}# end do_mymode()


#==============================================================================
sub after_create
{
  my ($s, $asp, $Upload) = @_;
  
  $asp->response->Write("Create Successful");
}# end after_create()


#==============================================================================
sub after_update
{
  my ($s, $asp, $Upload) = @_;
  
  $asp->response->Write("Update Successful");
}# end after_update()


#==============================================================================
sub after_delete
{
  my ($s, $asp) = @_;
  
  $asp->response->Write("Delete Successful");
}# end after_delete()

1;# return true:
