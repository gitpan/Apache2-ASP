#!perl

use strict;
use warnings 'all';
use Test::More tests => 2;
use File::Copy;

ok( copy( 't/sessiontest', '/tmp/apache2_asp_sessions' ) );
ok( copy( 't/sessiontest', '/tmp/apache2_asp_applications' ) );

