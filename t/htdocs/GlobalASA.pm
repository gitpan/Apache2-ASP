
package GlobalASA;
use base 'Apache2::ASP::GlobalASA';
use vars qw($Request $Response $Session $Application $Server $Form);
use Data::Dumper;

sub Session_OnStart
{
  $Session->{file_upload_root} = "$ENV{APACHE2_APPLICATION_ROOT}/MEDIA";
}

1;# return true:
