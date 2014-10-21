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
my $max = 100;
for( 1...$max )
{
  warn $_ if $_ % 20 == 0;
  my $res = $ua->get('/counter.asp');
  warn $res->content;
#  warn $res->content if $_ == 1;
}

my $diff = gettimeofday() - $start;
my $persec = $max / $diff;
warn "\n\t$persec requests/second";


