
package Apache2::ASP::Tag;

use strict;
use warnings 'all';
use vars qw(
  $Session  $Server
  $Request  $Response
  $Config   $Application
  $Form
);

sub new
{
  my ($class, %args) = @_;
  
  return bless \%args, $class;
}# end new()


#==============================================================================
sub _init_asp_objects
{
  my ($s) = @_;
  
  my $asp = $main::_ASP::ASP;
  
  $Session      = $asp->session;
  $Server       = $asp->server;
  $Request      = $asp->request;
  $Response     = $asp->response;
  $Form         = $asp->request->Form;
  $Application  = $asp->application;
  $Config       = $asp->config;
  
  no strict 'refs';
	my %saw = ($s => 1);
  foreach my $pkg ( ( $s, @{"$s\::ISA"} ) )
  {
    ${"$pkg\::Session"}     = $Session;
    ${"$pkg\::Server"}      = $Server;
    ${"$pkg\::Request"}     = $Request;
    ${"$pkg\::Response"}    = $Response;
    ${"$pkg\::Form"}        = $Form;
    ${"$pkg\::Application"} = $Application;
    ${"$pkg\::Config"}      = $Config;
		
		# Recurse upward:
		$pkg->init_asp_objects( $asp )
			unless $saw{$pkg}++;
  }# end foreach()
  
  return 1;
}# end _init_asp_objects()

1;# return true:

__END__

=pod

=head1 NAME

=head1 EXPERIMENTAL STATUS

B<NOTE>: This module and the entire tag model for Apache2::ASP is very experimental
at this point.  B<Do not use tags in your production code> because they B<will change in a future release>.

=head1 SYNOPSIS

  package My::Bold;
  
  # Your tag should subclass Apache2::ASP::Tag:
  use base 'Apache2::ASP::Tag';
  
  # Declare these variables if you want access to them:
  use vars qw(
    $Session  $Server
    $Request  $Response
    $Config   $Application
    $Form
  );
  
  # You must define this method:
  sub render
  {
    my ($s, $args, $innerHTML) = @_;
    
    return "<b>" . $innerHTML . "</b>";
  }# end render()
  
  1;# return true:

=head1 DESCRIPTION

=head1 PUBLIC METHODS

=head2 new( )

Returns a blessed hashref-based object.

=head1 ABSTRACT METHODS

=head2 render( $args, $innerHTML )

Should return a string.

=cut

