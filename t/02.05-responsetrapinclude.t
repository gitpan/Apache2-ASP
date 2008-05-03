#!perl -w

use strict;
use warnings 'all';
use base 'Apache2::ASP::Test::Base';
use Test::More 'no_plan';
use Data::Dumper;
use HTML::Form;

# Initialize our object:
my $s = __PACKAGE__->SUPER::new();

my $res = $s->ua->get("/responsetrapinclude.asp");

is(
  $res->content => 'Before TrapInclude
INCLUDE ME 1!<BR>
INCLUDE ME 2!<BR>
INCLUDE ME 3!<BR>
INCLUDE ME 4!<BR>
INCLUDE ME 5!<BR>
INCLUDE ME 6!<BR>
INCLUDE ME 7!<BR>
INCLUDE ME 8!<BR>
INCLUDE ME 9!<BR>
INCLUDE ME 10!<BR>


After TrapInclude
',
  "Response->Include worked correctly"
);

ok( ! eval{$s->ua->get("/bad-responsetrapinclude.asp")->is_success}, "/bad-responsetrapinclude.asp failed" );
#ok( ! eval{$s->ua->get("/syntax-error-trapinclude.asp")->is_success}, "/syntax-error-trapinclude.asp failed" );
