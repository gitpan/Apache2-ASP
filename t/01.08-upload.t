#!/usr/bin/env perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use base 'Apache2::ASP::Test::Base';

my $s = __PACKAGE__->SUPER::new();
ok( $s );

# Make the file to upload:
my $upload_filename = '/tmp/asp-upload-test.txt';
open my $ofh, '>', $upload_filename
  or die "Cannot open '$upload_filename' for writing: $!";
for( 1...10_000 )
{
  print $ofh "$_: This is a line of text\n";
}# end for()
close($ofh);

my $res = $s->ua->upload("/handlers/upload01?mode=create", [
  uploaded_file => [ $upload_filename ]
]);

use Data::Dumper;
warn Dumper( $res );

