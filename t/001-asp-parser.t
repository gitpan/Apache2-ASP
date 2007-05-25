#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';

use lib '../';
use_ok('Apache2::ASP::Parser');
use Cwd;

# Set the environment variable:
my $here = getcwd();
$ENV{APACHE2_APPLICATION_ROOT} = "$here/t";

# Simple "Hello, World" example:
my $text = <<'EOF';
<%= "Hello, World" %>
EOF
my $expected = q@$Response->Write(q~~);$Response->Write( "Hello, World" );$Response->Write(q~
~);@;
my $got = Apache2::ASP::Parser->parse_string( $text );
is( $got, $expected );

