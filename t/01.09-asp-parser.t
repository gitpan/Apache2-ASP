#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
use Test::Exception;
#use Devel::Cover;
use Apache2::ASP::Config;

# Start out simple:
use_ok('Apache2::ASP::Parser');

# Initialize the config:
my $config = Apache2::ASP::Config->new();

# Simple "Hello, World" example:
my $text = <<'EOF';
<%= "Hello, World" %>
EOF
my $expected = q@$Response->Write(q~~);$Response->Write( "Hello, World" );$Response->Write(q~
~);@;
my $got = Apache2::ASP::Parser->parse_string( $text );
is( $got, $expected );

# Try parsing a file:
my $file = $config->www_root . '/index.asp';
ok( Apache2::ASP::Parser->parse_file( $file ) );

# Try parsing a file that doesn't exist:
dies_ok
  { Apache2::ASP::Parser->parse_file( '/bob/franky/wilma/no.asp' ) };


