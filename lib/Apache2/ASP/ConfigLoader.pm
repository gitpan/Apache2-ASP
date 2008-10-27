
package Apache2::ASP::ConfigLoader;

use strict;
use warnings 'all';
use Apache2::ASP::ConfigFinder;
use Apache2::ASP::ConfigParser;
use XML::Simple ();
$XML::Simple::PREFERRED_PARSER = 'XML::Parser';

our $Configs = { };


#==============================================================================
sub load
{
  my ($s) = @_;
  
  my $path = Apache2::ASP::ConfigFinder->config_path;
  return $Configs->{$path} if $Configs->{$path};
  my $doc = XML::Simple::XMLin( $path,
    SuppressEmpty => '',
    ForceArray => [qw/ var /],
  );
  
  $path =~ s/\/conf\/[^\/]+$//;
  return $Configs->{$path} = Apache2::ASP::ConfigParser->new->parse( $doc, $path );
}# end parse()

1;# return true:

