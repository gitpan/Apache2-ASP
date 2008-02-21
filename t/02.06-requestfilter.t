#!perl -w

use strict;
use warnings 'all';
use base 'Apache2::ASP::Test::Base';
use Test::More 'no_plan';
use Data::Dumper;
use HTML::Form;

# Initialize our object:
my $s = __PACKAGE__->SUPER::new();

# Try to access a protected page:
my $res = $s->ua->get("/members_only/index.asp");
is(
  $res->headers->{location} => '/login.asp?return_url=%2Fmembers_only%2Findex.asp',
  "Got redirected correctly"
);

# Now pretend to be logged in:
$s->session->{logged_in} = 1;
$s->session->save;

# Try again:
$res = $s->ua->get("/members_only/index.asp");
is(
  $res->headers->{location} => undef,
  "Did not get redirected"
);
