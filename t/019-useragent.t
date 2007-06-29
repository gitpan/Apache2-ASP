#!perl

use strict;
use warnings 'all';
use Test::More 'no_plan';

use Apache2::ASP::Base;
use Apache2::ASP::Config;

use_ok('Apache2::ASP::Test::UserAgent');

my $config = Apache2::ASP::Config->new();
my $asp = Apache2::ASP::Base->new( $config );
my $ua = Apache2::ASP::Test::UserAgent->new( $asp );

my $SessionID;
for( 1...50 )
{
  ok( $ua->get( '/index.asp' )->is_success, 'GET /index.asp is good' );
  $SessionID ||= $ua->asp->session->{SessionID};
  is( $SessionID, $ua->asp->session->{SessionID}, 'SessionID was re-used' );
}# end for()
for( 1...50 )
{
  ok( $ua->post( '/index.asp', [ hello => 'world' ] )->is_success, 'POST /index.asp is good' );
  is( $SessionID, $ua->asp->session->{SessionID}, 'SessionID was re-used' );
}# end for()



__END__

{
  my $res = $ua->get( '/index.asp?a_field=a_value&b_field=b_value' );
  is( $res->content, 'Hello, World!' );
  my $headers = $res->headers;
  my ($set_cookie) = grep { m/Set\-Cookie/i } $headers->header_field_names;
  ok( $set_cookie, 'Set-Cookie header was sent' );
}

{
  my $res = $ua->post(
    '/index.asp?a_field=a_value&b_field=b_value',
    [
      c_field => 'c_value',
      d_field => 'd_value',
    ]
  );
  is( $res->content, 'Hello, World!' );
  my $headers = $res->headers;
  my ($set_cookie) = grep { m/Set\-Cookie/i } $headers->header_field_names;
  ok( (!$set_cookie), 'Set-Cookie header was *not* re-sent' );
}


{
  open my $ofh, '>', '/tmp/test_upload.txt';
  my $str = "This is the test string\n"x800;
  print $ofh $str;
  close($ofh);
  my $res = $ua->upload(
    '/handlers/TestUploadHandler',
    [
      c_field => 'c_value',
      d_field => 'd_value',
      fieldname => ['/tmp/test_upload.txt']
    ]
  );
  ok( $res->is_success, 'is_success' );
#  is( $res->content, $str );
  my $headers = $res->headers;
  my ($set_cookie) = grep { m/Set\-Cookie/i } $headers->header_field_names;
  ok( (!$set_cookie), 'Set-Cookie header was *not* re-sent' );
}





