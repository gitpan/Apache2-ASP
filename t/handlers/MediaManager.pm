
package MediaManager;

use strict;
use warnings 'all';
use base 'Apache2::ASP::MediaManager';
use vars qw(
  $Request $Response
  $Server $Session
  $Config $Application
  $Form
);
use Data::Dumper;

sub after_create
{
  my ($s, $asp, $Upload) = @_;
  
  $Response->Write( $Upload->{content_length} );
}# end after_create()


sub after_update
{
  my ($s, $asp, $Upload) = @_;
  
  $Response->Write( $Upload->{content_length} );
}# end after_update()

1;# return true:

