#!/usr/bin/env perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use base 'Apache2::ASP::Test::Base';

my $s = __PACKAGE__->SUPER::new();

my $res = $s->ua->get('/page-using-nested-masterpage.asp');
ok( $res->is_success );

unlike $res->content, qr/<asp:(PlaceHolder|PlaceHolderContent)/;


