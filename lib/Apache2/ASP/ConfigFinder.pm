
package Apache2::ASP::ConfigFinder;

use strict;
use warnings 'all';
use Cwd 'cwd';

our $CONFIGFILE = 'apache2-asp-config.xml';

#==============================================================================
sub config_path
{
  my $path = $CONFIGFILE;
  
  my $root = $ENV{DOCUMENT_ROOT} || cwd();
  
  # Try test dir:
  if( -f "$root/t/conf/$CONFIGFILE" )
  {
    return "$root/t/conf/$CONFIGFILE";
  }# end if()
  
  # Start moving up:
  for( 1...10 )
  {
    my $path = "$root/conf/$CONFIGFILE";
    return $path if -f $path;
    $root =~ s/\/[^\/]+$//
      or last;
  }# end for()
  
  die "CANNOT FIND '$CONFIGFILE'";
}# end config_path()


1;# return true:

