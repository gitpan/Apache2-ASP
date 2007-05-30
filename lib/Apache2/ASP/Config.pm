
package Apache2::ASP::Config;

our $VERSION = 0.08;

use strict;
use warnings;
use XML::Simple;


#==============================================================================
sub import
{
  my ($class, $option) = @_;

  # First load the configuration:
  my $file = "$ENV{APACHE2_APPLICATION_ROOT}/conf/apache2-asp-config.xml";
  my $xml = eval { XMLin( $file ) }
    or die "Cannot load $file: $@";
  $ENV{$_} = $xml->{$_} foreach keys %$xml;
  $ENV{APACHE2_ASP_DSN} = [
    "DBI:$xml->{db_driver}:$xml->{db_name}:$xml->{db_host}",
    $xml->{db_user},
    $xml->{db_pass}
  ];
  $ENV{APACHE2_ASP_SESSION_COOKIE_DOMAIN} = $xml->{session_cookie_domain};
  $ENV{APACHE2_ASP_SESSION_COOKIE_NAME}   = $xml->{session_cookie_name};
  
}# end import()

1;# return true:

