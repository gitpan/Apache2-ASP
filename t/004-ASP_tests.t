

use strict;
use warnings 'all';

use Apache2::ASP;
use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest qw( GET_BODY UPLOAD );
use Cwd;

plan tests => 17,
  sub { $^O ne 'MSWin32'};

# Make sure we can render a simple page:
{
  my $url = '/001-hello.asp';
  my $data = GET_BODY $url;
  ok( $data =~ m/Hello, World\!/ );
}

# A little more advanced:
{
  my $url = '/002-asp-expression.asp';
  my $data = GET_BODY $url;
  ok( $data =~ m/An\|ASP\|Expression\|Here/ );
}

# Form variables:
{
  my $url = '/003-form-variables.asp?name=John';
  my $data = GET_BODY $url;
  ok( $data =~ m/Hello there, John\./ );
}

# File upload: 1/3:
{
  my $url = '/004-upload.asp';
  my $pwd = getcwd();
  
  my $filename = "$pwd/$0.UPLOAD";
  my $str = "Hello, World Again! " x80000;
  open my $ofh, '>', $filename;
  print $ofh $str;
  close($ofh);
  my $res = UPLOAD $url, filename => $filename;
  unlink($filename);
  my $expected_size = length( $str );
  ok( $res->content =~ m/\b$expected_size\b/ );
}

# File upload: 2/3:
{
  my $url = '/005-upload.asp';
  my $pwd = getcwd();
  
  my $filename = "$pwd/$0.UPLOAD";
  my $str = "Hello, World! " x80000;
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

  ok( $str eq $res->content && $res->content eq $data );
}

# File upload: 3/3:
{
  my $url = '/handlers/TestHandler';
  my $pwd = getcwd();
  
  my $filename = "$pwd/$0.UPLOAD";
  my $str = "Hello, World! " x900_000;
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

  ok( 1 );
}

# Load test:
{
  my $url = '/002-asp-expression.asp';
  
  for( 1...10 )
  {
    my $data = GET_BODY $url;
    ok( 1 );
  }# end for()
}

# Controller test:
{
  my $url = '/handlers/Apache2_ASP_Handler';
  my $data = GET_BODY $url;
  
  ok( $data eq 'This is the default handler response.' );
}
