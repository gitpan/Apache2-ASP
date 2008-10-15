#!/usr/bin/env perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use Time::HiRes 'gettimeofday';

use_ok('Apache2::ASP::Test::UserAgent');
use_ok('Apache2::ASP::ConfigLoader');


my $ua = Apache2::ASP::Test::UserAgent->new(
  config => Apache2::ASP::ConfigLoader->load(),
);


my $start = gettimeofday();
for( 1...1000 )
{
  warn $_ if $_ % 100 == 0;
  my $res = $ua->get('/index.asp');
  warn $res->content if $_ == 1;
}

my $diff = gettimeofday() - $start;
my $persec = 1000 / $diff;
warn "$persec/second";


