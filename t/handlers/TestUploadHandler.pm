
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

warn "OKOKOKOOOK";

use Data::Dumper;
warn "Form: " . Dumper( $Form );
  
  if( my $ifh = $asp->request->FileUpload('filename') )
  {
warn "Got an IFH";
    while( my $line = <$ifh> )
    {
warn "LINE: $line";
      $Response->Write( $line );
    }# end while()
    close($ifh);
  }# end if()

warn "DONEDONEDONE";
}# end run()

1;

