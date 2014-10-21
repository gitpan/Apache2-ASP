#!/usr/bin/env perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';

use_ok('Apache2::ASP::Test::UserAgent');
#use_ok('Apache2::ASP::ConfigLoader');
#use_ok('Apache2::ASP::HTTPContext');
#use_ok('Apache2::ASP::Mock::RequestRec');
#use_ok('Apache2::ASP::SimpleCGI');


my $ua = Apache2::ASP::Test::UserAgent->new(
  config => Apache2::ASP::ConfigLoader->load(),
);

for( 1...10 )
{
  my $res = $ua->get('/index.asp?somevar=someval');
  ok( $res->content );
warn $res->content . "\n" if $_ == 1;
}

