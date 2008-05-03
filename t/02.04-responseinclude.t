#!perl -w

use strict;
use warnings 'all';
use base 'Apache2::ASP::Test::Base';
use Test::More 'no_plan';
use Data::Dumper;
use HTML::Form;

# Initialize our object:
my $s = __PACKAGE__->SUPER::new();

my $res = $s->ua->get("/responseinclude.asp");

is(
  $res->content => 'Before Include
Include Me 1!<br>
Include Me 2!<br>
Include Me 3!<br>
Include Me 4!<br>
Include Me 5!<br>
Include Me 6!<br>
Include Me 7!<br>
Include Me 8!<br>
Include Me 9!<br>
Include Me 10!<br>


After Include
',
  "Response->Include worked correctly"
);


ok( ! eval{$s->ua->get("/bad-responseinclude.asp")->is_success}, "/bad-responseinclude.asp failed" );
#ok( ! eval{$s->ua->get("/syntax-error-include.asp")->is_success}, "/syntax-error-include.asp failed" );

