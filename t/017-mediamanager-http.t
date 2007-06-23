#!perl

use strict;
use warnings 'all';
use Apache::Test qw(-withtestmore);
use Apache::TestUtil;
use Apache::TestRequest qw( GET_BODY GET UPLOAD );
use Cwd;
use lib '../blib/lib';
use lib 'blib/lib';
use Apache2::ASP::Config;

plan tests => 5,
  sub { $^O ne 'MSWin32'};

my $config = Apache2::ASP::Config->new();


# MediaManager tests:
{
  my $url = "/handlers/MediaManager";
  
  my $filename = $config->application_root . "/$0.UPLOAD";
  $filename =~ s/\/t\/t/\/t/;
  
  my $str = "Hello, World! " x900;
  open my $ofh, '>', $filename;
  print $ofh $str;
  close($ofh);
  
  # Test out the "create" mode:
  my $res = UPLOAD $url,
            filename => $filename,
            mode  => 'create';
  
  # We should have been told that the Create is Successful:
  my $expected = 'Create Successful';
  is( $expected, $res->content, 'Create works' );
  
  # Test out the "update" mode:
  $res = UPLOAD $url,
            filename => $filename,
            mode  => 'update';
  
  # We should have been told that the Update is Successful:
  $expected = 'Update Successful';
  is( $expected, $res->content, 'Update works' );
  
  # Change the URL to the file's URL itself:
  my $file = "$0.UPLOAD";
  $file =~ s/^t\///;
  $url = "/media/$file";
  
  # Make sure we can download the file:
  $res = GET $url;
  is( $res->content, $str, 'Download works' );
  
  # Test out the "mymode" extension hook:
  $res = GET "$url?mode=mymode";
  is( $res->content, 'mymode Successful', 'mymode works' );
  
  # Make sure we can delete the file:
  $res = GET "$url?mode=delete";
  is( $res->content, 'Delete Successful', 'Delete works' );
}





