
package Apache2::ASP::Test::Base;

use strict;
use warnings 'all';
use Apache2::ASP::ConfigLoader;
use Apache2::ASP::Test::UserAgent;
use Apache2::ASP::Test::Fixtures;
use Data::Properties::YAML;


#==============================================================================
sub new
{
  my $class = shift;
  
  my $config = Apache2::ASP::ConfigLoader->load();
  
  # Our test fixtures:
  my $data = Apache2::ASP::Test::Fixtures->new(
    properties_file => $config->web->application_root . '/etc/test_fixtures.yaml'
  ) if -f $config->web->application_root . '/etc/test_fixtures.yaml';
  
  # Our diagnostic messages:
  my $diag = Data::Properties::YAML->new(
    properties_file => $config->web->application_root . '/etc/properties.yaml'
  ) if -f $config->web->application_root . '/etc/properties.yaml';
  
  my $s = bless {
    # TBD:
    ua     => Apache2::ASP::Test::UserAgent->new( config => $config ),
    config => $config,
    data   => $data,
    diags  => $diag,
  }, $class;
  
  return $s;
}# end new()


#==============================================================================
sub ua { $_[0]->{ua} }
sub config { $_[0]->{config} }
sub data { $_[0]->{data} }
sub diags { $_[0]->{diags} }
sub session { $_[0]->{ua}->context->session }

1;# return true:

