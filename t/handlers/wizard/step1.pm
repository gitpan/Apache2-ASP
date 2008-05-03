
package wizard::step1;

use strict;
use warnings 'all';
use base 'Apache2::ASP::FormHandler';

use vars qw(
  $Form     $Application
  $Config   $Request
  $Session  $Response
  $Server
);

sub run
{
  $Session->{__lastArgs} = $Form;
  $Response->Redirect("/wizard/step2.asp");
}# end run()

1;# return true()


