
package TestUploadHandler;

use strict;
use base 'Apache2::ASP::UploadHandler';
use vars qw(
  $Request $Form $Response $Server $Session $Application $Config
);


#==============================================================================
sub run
{
  my ($s, $asp) = @_;
  $s->init_asp_objects($asp);
  
  if( my $ifh = $asp->request->FileUpload('filename') )
  {
    while( my $line = <$ifh> )
    {
      $Response->Write( $line );
    }# end while()
    close($ifh);
  }# end if()
}# end run()

1;

