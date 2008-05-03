#!perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use base 'Apache2::ASP::Test::Base';
use HTML::Form;

my $s = __PACKAGE__->SUPER::new();

# Step 1:
{
  # Complete the form on the first page:
  my $form = HTML::Form->parse( $s->ua->get("/wizard/step1.asp")->content, '/' );
  ok( $form, 'Got form' );
  $form->find_input('your_name')->value('Foo Bar');
  $form->find_input('favorite_color')->value('orange');
  
  # Submit the form:
  my $res = $s->ua->submit_form( $form );
  
  # Did we get redirected?:
  is( $res->header('location') => '/wizard/step2.asp' );
  
  # Follow the redirect:
  $res = $s->ua->get( $res->header('location') );
  
  # Did our data from the first form make it onto the next page? (via $Session->{_lastArgs}):
  is( $res->content => 'Foo Bar:orange' );
}

