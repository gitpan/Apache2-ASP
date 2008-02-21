#!perl -w

use strict;
use warnings 'all';
use base 'Apache2::ASP::Test::Base';
use Test::More skip_all => "Uploads only work within a real CGI environment";
use Data::Dumper;
use HTML::Form;

# Initialize our object:
my $s = __PACKAGE__->SUPER::new();

open my $ofh, '>', "/tmp/uploadtest"
  or die "Cannot open: $!";
for( 1...100 )
{
  print $ofh "ANOTHER LINE\n";
}# end for()
close($ofh);

my $res = $s->ua->upload("/handlers/TestUploadHandler", [
  filename => ["/tmp/uploadtest"]
]);

warn $res->content;

