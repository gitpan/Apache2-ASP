#!perl

use strict;
use warnings 'all';
use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest qw( GET_BODY GET UPLOAD );

plan tests => 100,
  sub { $^O ne 'MSWin32'};

# Make sure we can render a simple page:
for( 1...100 )
{
  my $url = '/index.asp';
  my $data = GET_BODY $url;
  ok( $data =~ m/Hello, World\!/ );
}

