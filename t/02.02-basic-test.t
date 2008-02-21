#!perl -w

use strict;
use warnings 'all';
use base 'Apache2::ASP::Test::Base';
use Test::More 'no_plan';
use Data::Dumper;
use HTML::Form;

# Initialize our object:
my $s = __PACKAGE__->SUPER::new();

my $res = $s->ua->get("/index.asp");
is(
  $res->content => "Hello, World!"
);
is(
  $res->headers->{location} => undef
);
