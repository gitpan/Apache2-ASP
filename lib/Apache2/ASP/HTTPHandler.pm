
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
    %modes
  );
  sub VARS { @VARS }
}
use vars __PACKAGE__->VARS;


#==============================================================================
sub new
{
  my ($class) = shift;
  
  return bless { @_ }, $class;
}# end new()


#==============================================================================
sub before_run { }
sub after_run  { }
sub run;


#==============================================================================
sub init_asp_objects
{
  my ($s, $context) = @_;
  
  no strict 'refs';
  my $selfclass = ref($s) || $s;
  my @classes = (
    grep { $_->isa('Apache2::ASP::HTTPHandler') } 
    ( $selfclass, @{"$selfclass\::ISA"} )
  );
  foreach my $class ( @classes )
  {
    ${"$class\::Request"}     = $context->request;
    ${"$class\::Response"}    = $context->response;
    ${"$class\::Server"}      = $context->server;
    ${"$class\::Session"}     = $context->session;
    ${"$class\::Application"} = $context->application;
    ${"$class\::Config"}      = $context->config;
    ${"$class\::Form"}        = $context->request->Form;
    ${"$class\::Stash"}       = $context->stash;
  }# end foreach()
  
  1;
}# end init_asp_objects()


#==============================================================================
sub register_mode
{
  my ($s, %info) = @_;
  
  $modes{ $info{name} } = $info{handler};
}# end register_mode()


#==============================================================================
sub modes
{
  my $s = shift;
  my $key = shift;
  
  @_ ? $modes{$key} = shift : $modes{$key};
}# end modes()

1;# return true:

