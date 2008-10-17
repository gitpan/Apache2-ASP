
package upload01;

use strict;
use warnings 'all';
use base 'Apache2::ASP::MediaManager';
use vars __PACKAGE__->VARS;

sub before_create
{
  my ($s, $context, $Upload) = @_;
  
  warn "UPLOADING: '" . $Upload->upload->filename . "'";
}# end before_create()


sub after_create
{
  my ($s, $context, $Upload) = @_;

  warn "DONE!!!!: '" . $Upload->upload->filename . "'";
}# end after_create()

1;# return true:

