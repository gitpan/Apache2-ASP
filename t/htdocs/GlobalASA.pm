
package GlobalASA;
use base 'Apache2::ASP::GlobalASA';
use vars qw($Request $Response $Session $Application $Server $Form);
use Data::Dumper;

sub Script_OnStart
{
  # do stuff here.
#  $Request->SetUploadHook(sub {
#    my ($upload, $len, $data) = @_;
#    my $script = $Request->ServerVariables("SCRIPT_FILENAME");
#    warn "OK: Request to '$script': " . Dumper($upload);
#    1;
#  });
}


sub Script_OnEnd
{
#  $Request->SetUploadHook(sub {});
}

1;# return true:
