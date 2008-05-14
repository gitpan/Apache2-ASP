#!perl -w

use strict;
use warnings 'all';
use base 'Apache2::ASP::Test::Base';
use Test::More 'no_plan';
use Data::Dumper;
use HTML::Form;

# Initialize our object:
my $s = __PACKAGE__->SUPER::new();

open my $ofh, '>', "/tmp/uploadtest"
  or die "Cannot open: $!";
my $data = "ANOTHER LINE ANOTHER LINE ANOTHER LINE ANOTHER LINE ANOTHER LINE ANOTHER LINE \n"x10_000;
print $ofh $data;
close($ofh);

my $res = $s->ua->upload("/handlers/TestUploadHandler", [
  uploaded_file => ["/tmp/uploadtest"],
  color    => "red",
  name     => "Frank",
]);

is( $res->content => $data, "File was uploaded correctly" );

