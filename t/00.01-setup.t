#!perl

use strict;
use warnings 'all';
use Test::More tests => 2;
use File::Copy;

if( $^O =~ m/mswin32/i )
{
  my $tmp = $ENV{TMP} || $ENV{TEMP};
  ok( copy( 't/sessiontest', "$tmp\\apache2_asp_sessions"  ) );
  ok( copy( 't/sessiontest', "$tmp\\apache2_asp_applications" ) );
}
else
{
  ok( copy( 't/sessiontest', '/tmp/apache2_asp_sessions' ) );
  ok( copy( 't/sessiontest', '/tmp/apache2_asp_applications' ) );
}# end if()
