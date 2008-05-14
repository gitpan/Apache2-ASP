#!perl -w

use strict;
use warnings 'all';
use base 'Apache2::ASP::Test::Base';
use Test::More 'no_plan';
use Data::Dumper;
use HTML::Form;

# Initialize our object:
my $s = __PACKAGE__->SUPER::new();

# Get a chunk of data from the properties object:
my $person = $s->data->register_successful->as_hash;

# Did we get something, and is it exactly what we expected?
ok( $person, "Got person");
is_deeply(
  $person => {
    'password2'   => 'secret-password',
    'email2'      => 'test123@email.com',
    'middle_name' => 'N',
    'username'    => 'unit-test',
    'last_name'   => 'BEANS',
    'email'       => 'test123@email.com',
    'password'    => 'secret-password',
    'first_name'  => 'FRANK'
  },
  "Person contains the correct data and structure."
);
