#!/usr/bin/env perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';

use_ok('Apache2::ASP::ConfigLoader');

for( 1...1 )
{
  my $config = Apache2::ASP::ConfigLoader->load;

  is(
    $config->errors->error_handler => 'My::ErrorHandler'
  );
}

