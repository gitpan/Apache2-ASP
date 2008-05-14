
package TestHandler;

use strict;
use base 'Apache2::ASP::Handler';

use vars qw(
  %modes
  $Request $Response
  $Session $Application
  $Server $Form
  $Config
);

__PACKAGE__->register_mode(
  name    => 'special_mode',
  handler => sub {
    my ($s, $asp) = @_;
    $asp->response->Write("special_mode works");
  }
);

1;
