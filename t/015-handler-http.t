#!perl

use strict;
use warnings 'all';
use Apache::Test qw(-withtestmore);
use Apache::TestUtil;
use Apache::TestRequest qw( GET_BODY GET UPLOAD );

plan tests => 2,
  sub { $^O ne 'MSWin32'};

# Make sure we can render a simple handler:
{
  my $url = '/handlers/TestHandler';
  my $data = GET_BODY $url;
  is( $data, 'This is the default handler response.', "$url works" );
}

# Make sure we can render a simple handler + mode:
{
  my $url = '/handlers/TestHandler?mode=special_mode';
  my $data = GET_BODY $url;
  is( $data, 'special_mode works', "$url works" );
}

