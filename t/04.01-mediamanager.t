#!perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use base 'Apache2::ASP::Test::Base';
use HTML::Form;

my $s = __PACKAGE__->SUPER::new();



# Step 1 - upload a file:
{
  # Prepare our file for uploading:
  open my $ofh, '>', "/tmp/uploadtest"
    or die "Cannot open: $!";
  my $data = "ANOTHER LINE ANOTHER LINE ANOTHER LINE ANOTHER LINE ANOTHER LINE ANOTHER LINE \n"x10_000;
  print $ofh $data;
  close($ofh);
  my $res = $s->ua->upload("/handlers/MediaManager", [
    filename => ["/tmp/uploadtest"],
    mode     => 'create',
  ]);

  is( $res->content => '790186' => 'Content length is correct (including other params)' );
}

# Step 2 - download that same file:
{
  my $res = $s->ua->get("/handlers/MediaManager?file=uploadtest");
  is( length($res->content) => -s '/tmp/uploadtest' => 'downloaded file size is correct' );
}

# Step 3 - Update the file:
{
  # Prepare our file for uploading:
  open my $ofh, '>', "/tmp/uploadtest"
    or die "Cannot open: $!";
  my $data = "THIS IS THE UPDATED FILE 1234567890 \n"x1_000;
  print $ofh $data;
  close($ofh);
  my $res = $s->ua->upload("/handlers/MediaManager", [
    filename => ["/tmp/uploadtest"],
    mode     => 'edit',
  ]);

  is( $res->content => '37184' => 'Content length is correct (including other params)' );
}

# Step 4 - download the updated file:
{
  my $res = $s->ua->get("/handlers/MediaManager?file=uploadtest");
  is( length($res->content) => -s '/tmp/uploadtest' => 'downloaded file size is correct' );
}

# Step 5 - delete the file:
{
  $s->ua->get("/handlers/MediaManager?file=uploadtest&mode=delete");
  my $res = $s->ua->get("/handlers/MediaManager?file=uploadtest");
  ok( ! $res->content => 'file has been deleted' );
  ok( ! $res->is_success => 'attempt to download was not "is_successful"');
  is( $res->code => 404, 'response code is 404');
}



