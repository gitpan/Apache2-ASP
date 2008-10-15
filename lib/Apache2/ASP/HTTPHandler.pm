
package Apache2::ASP::HTTPHandler;

use strict;
use warnings 'all';
BEGIN {
  use vars '@VARS';
  our @VARS = qw(
    $Request  $Response
    $Server   $Application
    $Session  $Form
    $Config   $Stash
  );
  use vars @VARS;
}

sub VARS { @VARS }


#==============================================================================
sub new
{
  my ($class) = shift;
  
  return bless { @_ }, $class;
}# end new()


#==============================================================================
sub run;


#==============================================================================
sub init_asp_objects
{
  my ($s, $context) = @_;
  
  no strict 'refs';
  my $selfclass = ref($s) || $s;
  foreach my $class ( grep { $_->isa('Apache2::ASP::HTTPHandler') } ( $selfclass, @{"$selfclass\::ISA"} ) )
  {
    ${"$class\::Request"}     = $context->request;
    ${"$class\::Response"}    = $context->response;
    ${"$class\::Server"}      = $context->server;
    ${"$class\::Session"}     = $context->session;
    ${"$class\::Application"} = $context->application;
    ${"$class\::Config"}      = $context->config;
    ${"$class\::Form"}        = $context->request->Form;
    ${"$class\::Stash"}        = $context->stash;
  }# end foreach()
  
  1;
}# end init_asp_objects()

1;# return true:

