
package Apache2::ASP::Test::Base;

use strict;
use warnings 'all';
use Apache2::ASP::ConfigLoader;
use Apache2::ASP::Test::UserAgent;


#==============================================================================
sub new
{
  my $class = shift;
  
  my $config = Apache2::ASP::ConfigLoader->load();
  my $s = bless {
    # TBD:
    ua     => Apache2::ASP::Test::UserAgent->new( config => $config ),
    config => $config,
  }, $class;
  
  return $s;
}# end new()


#==============================================================================
sub ua { $_[0]->{ua} }
sub config { $_[0]->{config} }

1;# return true:

