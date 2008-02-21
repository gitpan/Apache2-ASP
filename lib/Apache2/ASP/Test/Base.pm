
package Apache2::ASP::Test::Base;

use strict;
use warnings 'all';
use lib qw(
  lib
  t/lib
);
use Apache2::ASP::Config;
use Apache2::ASP::Base;
use Apache2::ASP::Test::UserAgent;
use Apache2::ASP::Test::Fixtures;
use Data::Properties::YAML;
use HTML::Form;
use Data::Dumper;


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  my $config = Apache2::ASP::Config->new;
  my $asp = Apache2::ASP::Base->new( $config );
  my $ua = Apache2::ASP::Test::UserAgent->new( $asp );

  # Our test fixtures:
  my $data = Apache2::ASP::Test::Fixtures->new(
    properties_file => $config->application_root . '/etc/test_fixtures.yaml'
  );
  
  # Our diagnostic messages:
  my $diag = Data::Properties::YAML->new(
    properties_file => $config->application_root . '/etc/properties.yaml'
  );
  
  return bless {
    config => $config,
    asp    => $asp,
    ua     => $ua,
    data   => $data,
    diags  => $diag,
  }, $class;
}# end new()


#==============================================================================
# Public properties:
sub config  { $_[0]->{config}           }
sub asp     { $_[0]->{ua}->asp          }
sub ua      { $_[0]->{ua}               }
sub session { $_[0]->{ua}->asp->session }
sub data    { $_[0]->{data}             }
sub diags   { $_[0]->{diags}            }

1;# return true:
