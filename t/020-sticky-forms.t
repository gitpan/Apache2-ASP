#!perl

use strict;
use warnings 'all';
use Test::More 'no_plan';

use Apache2::ASP::Base;
use Apache2::ASP::Config;
use Apache2::ASP::Test::UserAgent;
use HTML::Form;

my $config = Apache2::ASP::Config->new();
my $asp = Apache2::ASP::Base->new( $config );
my $ua = Apache2::ASP::Test::UserAgent->new( $asp );

ok( $ua->get( '/sticky.asp' )->is_success, 'GET /sticky.asp is good' );

my $val1 = 0;
my $val2 = 0;
my $res = $ua->get("/sticky.asp?field1=$val1&field2=$val2");

for( 1...50 )
{
  my $form = HTML::Form->parse( $res->content, '/sticky.asp' );
  is( $form->find_input( 'field1' )->value, $val1, 'field1 is right' );
  is( $form->find_input( 'field2' )->value, $val2, 'field2 is right' );
  $val1++;
  $val2++;
  $form->find_input( 'field1' )->value( $val1 );
  $form->find_input( 'field2' )->value( $val2 );
  $res = $ua->submit_form( $form );
}# end for()

