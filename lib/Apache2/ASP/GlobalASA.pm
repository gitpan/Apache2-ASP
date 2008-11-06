
package Apache2::ASP::GlobalASA;

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


#==============================================================================
sub VARS { @VARS }


#==============================================================================
sub init_asp_objects
{
  my ($s, $context) = @_;
  
  no strict 'refs';
  my $selfclass = ref($s) || $s;
  
  # Get each of this classes' superclasses, and theirs as well, recursively:
  my %c = map { $_ => 1 } (
    grep { $_->isa('Apache2::ASP::HTTPHandler') } 
    ( $selfclass, @{"$selfclass\::ISA"} )
  );
  map { $c{$_}++ } map {
    @{"$_\::ISA"}
  } keys(%c);
  my @classes = keys(%c);
  
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
}# end init_asp_objects()


#==============================================================================
sub Application_OnStart()
{

}# end Application_OnStart()


#==============================================================================
sub Application_OnEnd()
{

}# end Application_OnEnd()


#==============================================================================
sub Server_OnStart()
{

}# end Server_OnStart()


#==============================================================================
sub Server_OnEnd()
{

}# end Server_OnEnd()


#==============================================================================
sub Session_OnStart()
{

}# end Session_OnStart()


#==============================================================================
sub Session_OnEnd()
{

}# end Session_OnEnd()


#==============================================================================
sub Script_OnStart()
{

}# end Script_OnStart()


#==============================================================================
sub Script_OnEnd()
{

}# end Script_OnEnd()


#==============================================================================
sub Script_OnError($);

1;# return true:

