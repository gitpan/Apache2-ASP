#!perl

use strict;
use warnings 'all';
use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest qw( GET_BODY GET UPLOAD );
use Cwd;
use lib '../blib/lib';
use lib 'blib/lib';
use Apache2::ASP::Config;

plan tests => 1,
  sub { $^O ne 'MSWin32'};

my $config = Apache2::ASP::Config->new();

# Make sure we can upload something:
{
  my $url = '/handlers/TestUploadHandler';
  
  my $filename = $config->application_root . "/$0.UPLOAD";
  $filename =~ s/\/t\/t/\/t/;
  my $str = "Hello, World! " x9;
  open my $ofh, '>', $filename;
  print $ofh $str;
  close($ofh);
  my $res = UPLOAD $url, filename => $filename;
  
  # Read our copy into memory:
  open my $ifh, '<', $filename;
  local $/ = '';
  binmode($ifh);
  my $data = <$ifh>;
  close( $ifh );

  ok( $res->content eq $data );
}
