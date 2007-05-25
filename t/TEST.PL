#!perl

use strict;
use warnings FATAL => 'all';
  
use lib qw(lib);
use Cwd;
  
use Apache::TestRunPerl ();

# Set the environment variable:
my $here = getcwd();
$ENV{APACHE2_APPLICATION_ROOT} = "$here/t";
  
Apache::TestRunPerl->new->run(@ARGV);

