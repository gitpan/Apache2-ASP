
package Apache2::ASP::ConfigLoader;

use strict;
use warnings 'all';
use Apache2::ASP::ConfigFinder;
use Apache2::ASP::ConfigParser;
use XML::Simple ();
$XML::Simple::PREFERRED_PARSER = 'XML::Parser';


#==============================================================================
sub load
{
  my ($s) = @_;
  
  my $path = Apache2::ASP::ConfigFinder->config_path;
  my $doc = XML::Simple::XMLin( $path,
    SuppressEmpty => '',
    Cache => 'storable',
    ForceArray => [qw/ var /],
  );
  
  $path =~ s/\/conf\/[^\/]+$//;
  return Apache2::ASP::ConfigParser->new->parse( $doc, $path );
}# end parse()

1;# return true:

