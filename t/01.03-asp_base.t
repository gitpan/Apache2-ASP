#!perl

use strict;
use warnings 'all';
use Test::More 'no_plan';
use Test::Exception;

use base 'Apache2::ASP::Test::Base';
my $s = __PACKAGE__->SUPER::new();

for( 1...100 )
{
  is( $s->ua->get('/index.asp')->content, 'Hello, World!' );
}

