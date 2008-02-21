#!perl -w

use strict;
use warnings 'all';
use base 'Apache2::ASP::Test::Base';
use Test::More 'no_plan';
use Data::Dumper;
use HTML::Form;

# Initialize our object:
my $s = __PACKAGE__->SUPER::new();

my $res = $s->ua->post("/form01.asp", [
  fruit => 'apple',
  fruit => 'cherry',
  fruit => 'peach'
]);

my $form = HTML::Form->parse( $res->content, '/' );
is(
  $form->find_input('result')->value => q~$VAR1 = [
          'apple',
          'cherry',
          'peach'
        ];
~,
  "Form results are correct"
);

$res = $s->ua->get("/form01.asp?fruit=apple&fruit=cherry&fruit=banana");

$form = HTML::Form->parse( $res->content, '/' );
is(
  $form->find_input('result')->value => q~$VAR1 = [
          'apple',
          'cherry',
          'banana'
        ];
~,
  "Form results are correct"
);

