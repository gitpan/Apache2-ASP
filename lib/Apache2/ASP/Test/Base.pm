
package Apache2::ASP::Test::Base;

use strict;
use warnings 'all';
use lib qw(
  lib
  t/lib
);
#use Apache2::ASP::Config;
#use Apache2::ASP::Base;
use Apache2::ASP::Test::UserAgent;
use Apache2::ASP::Test::Fixtures;
use Data::Properties::YAML;
use Data::Dumper;


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  my $config = Apache2::ASP::Config->new;
  my $ua = Apache2::ASP::Test::UserAgent->new( );

  # Our test fixtures:
  my $data = Apache2::ASP::Test::Fixtures->new(
    properties_file => $config->application_root . '/etc/test_fixtures.yaml'
  ) if -f $config->application_root . '/etc/test_fixtures.yaml';
  
  # Our diagnostic messages:
  my $diag = Data::Properties::YAML->new(
    properties_file => $config->application_root . '/etc/properties.yaml'
  ) if -f $config->application_root . '/etc/properties.yaml';
  
  return bless {
    ua     => $ua,
    data   => $data,
    diags  => $diag,
  }, $class;
}# end new()


#==============================================================================
# Public properties:
sub config  { $_[0]->{ua}->{config}     }
sub asp     { $_[0]->{ua}->asp          }
sub ua      { $_[0]->{ua}               }
sub session { $_[0]->{ua}->asp->session }
sub data    { $_[0]->{data}             }
sub diags   { $_[0]->{diags}            }

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::Test::Base - Base class for Apache2::ASP unit tests

=head1 SYNOPSIS

  #!perl -w
  
  use strict;
  use warnings 'all';
  use base 'Apache2::ASP::Test::Base';
  use Test::More 'no_plan';
  
  # Initialize our object:
  my $s = __PACKAGE__->SUPER::new();
  
  my $res = $s->ua->get("/hello.asp");
  is(
    $res->is_success => 1,
    "Got /hello.asp successfully."
  );
  
  like(
    $res->content,
    qr/Hello, World\!/,
    "The content of /hello.asp looks good."
  );

=head1 DESCRIPTION

C<Apache2::ASP::Test::Base> brings simplicity to writing unit tests for your L<Apache2::ASP> web applications.

=head1 METHODS

=head2 new( )

Returns a new C<Apache2::ASP::Test::Base> object.

=head1 PUBLIC PROPERTIES

=head2 config

Returns the current active instance of L<Apache2::ASP::Config> in effect.

=head2 asp

Returns the current L<Apache2::ASP::Base> object.

=head2 ua

Returns the current L<Apache2::ASP::Test::UserAgent> object.

=head2 session

Returns the current L<Apache2::ASP::SessionStateManager> object (or an instance of your specified subclass of it).

=head2 data

If C<$config.application_root/etc/test_fixtures.yaml> exists and can be parsed by L<YAML>,
C<data> will return the current L<Apache2::ASP::Test::Fixtures> object.

=head2 diags

If C<$config.application_root/etc/test_fixtures.yaml> exists and can be parsed by L<YAML>,
C<data> will return the current L<Data::Properties::YAML> object.

=head1 SEE ALSO

The tests under the C<t/> folder in this distribution, which make extensive use of C<Apache2::ASP::Test::Base>.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-ASP> to submit bug reports.

=head1 HOMEPAGE

Please visit the Apache2::ASP homepage at L<http://www.devstack.com/> to see examples
of Apache2::ASP in action.

=head1 AUTHOR

John Drago L<mailto:jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut
