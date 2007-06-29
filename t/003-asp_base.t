#!perl

use strict;
use warnings 'all';
use Test::More 'no_plan';
use Test::Exception;

use Apache2::ASP::Base;
use Apache2::ASP::Config;
use Apache2::ASP::Test::UserAgent;

my $config = Apache2::ASP::Config->new();
my $asp = Apache2::ASP::Base->new( $config );
my $ua = Apache2::ASP::Test::UserAgent->new( $asp );

for( 1...100 )
{
  is( $ua->get('/index.asp')->content, 'Hello, World!' );
}

