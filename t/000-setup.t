#!perl

use strict;
use warnings 'all';
use Test::More tests => 1;
use File::Copy;

ok( copy( 't/sessiontest', '/tmp/apache2_asp_state' ) );

