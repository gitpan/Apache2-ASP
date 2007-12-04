
package Apache2::ASP::GlobalASA;

use strict;
use warnings 'all';

use vars qw($Request $Response $Session $Application $Server $Form $Config);


#==============================================================================
sub new
{
  my ($class, $asp) = @_;
  my $s = bless {
    asp => $asp
  }, $class;
  
  $s->_init_globals();
  return $s;
}# end new()


#==============================================================================
sub _init_globals
{
  my ($s) = @_;
  
  no strict 'refs';
  my $class = ref($s);
  $Request      = ${"$class\::Request"}     = $s->{asp}->request;
  $Response     = ${"$class\::Response"}    = $s->{asp}->response;
  $Session      = ${"$class\::Session"}     = $s->{asp}->session;
  $Form         = ${"$class\::Form"}        = $s->{asp}->request->Form;
  $Application  = ${"$class\::Application"} = $s->{asp}->application;
  $Server       = ${"$class\::Server"}      = $s->{asp}->server;
  $Config       = ${"$class\::Config"}      = $s->{asp}->config;
  
  return 1;
}# end _init_globals()


#==============================================================================
sub Application_OnStart
{
  
}# end Application_OnStart()


#==============================================================================
sub Script_OnParse
{
  my ($script_ref) = @_;
}# end Script_OnParse()


#==============================================================================
sub Script_OnFlush
{
  my ($ref) = @_;
}# end Script_OnFlush()


#==============================================================================
sub Script_OnStart
{
  
}# end Script_OnStart()


#==============================================================================
sub Script_OnEnd
{
  
}# end Script_OnEnd()

#==============================================================================
sub Script_OnError
{
  my ($error) = @_;
  $Response->Write(qq{<pre class="fatal_error">$error</pre>});
  warn $error;
  $Response->End;
}# end Script_OnError()


#==============================================================================
sub Session_OnStart
{
  
}# end Session_OnStart()


#==============================================================================
sub DESTROY { }

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::GlobalASA - Base class for your GlobalASA

=head1 SYNOPSIS

  package DefaultApp::GlobalASA;
  use base 'Apache2::ASP::GlobalASA';
  use vars qw($Request $Response $Session $Application $Server $Form);
  
  # Override any methods here:
  
  # Executed at the beginning of *every* ASP script:
  sub Script_OnStart
  {
    warn "Starting up script!";
  }# end Script_OnStart()
  
  #
  # Special error-handling method:
  sub Script_OnError
  {
    my $stack = shift;
    
    # Log the error:
    warn "[" . localtime() . "] An error has occurred: " . $stack->as_string;
    
    # Print something friendly:
    $Response->Write("Sorry for the inconvenience.  Please try again later.");
    
    # Email the webmaster:
    $Server->Mail(
      To      => 'me@mydomain.com',
      Subject => '500 Server error',
      Message => "Please look at the following error:\n\n" . $stack->as_string
    );
    
    # Done!
    $Response->End;
  }# end Script_OnError()
  
  1;# return true:

=head1 DESCRIPTION

The C<Apache2::ASP::GlobalASA> class is mostly analogous to the C<Global.asa> or 
C<Global.asx> of Microsoft ASP and ASP.Net web applications.

Simply by overriding a few methods you can completely change the behavior of your
web application.

=head1 OVERRIDABLE METHODS

=head2 new( $asp )

Returns a new GlobalASA object.

=head2 Application_OnStart( )

Called just before setting up the C<$Session> object, but only if it has never been called
for this application before.

=head2 Script_OnParse( $source_ref )

Called after a script's contents have been read from disk, but before
it has been parsed by C<Apache2::ASP::Parser>.

If the script is encrypted or requires a source filter, this is the time
to do that kind of pre-processing.

=head2 Script_OnFlush( $buffer_ref )

Called *just* before $Response->Flush is called.  Passed a reference to the output buffer,
here one can perform any final adjustments to the resulting HTML code.

For example, fill in HTML form fields or remove excess whitespace.

=head2 Session_OnStart( )

Called after C<Script_OnParse()> but before C<Script_OnStart()>, this is a good
place to set any Session variables that must be present at all times.

=head2 Script_OnStart( )

Called after the script has been parsed, but before it is executed, C<Script_OnStart()>
is a good place to check the logged-in status of a user.

For example:

  sub Script_OnStart
  {
    my $script = $Request->ServerVariables("SCRIPT_FILENAME");
    if( $script =~ m/^\/members\-only\/.*/ )
    {
      # User tried to access the /members-only area
      if( ! $Session->{logged_in} )
      {
        # Not logged in!
        $Session->{error} = "Please log in to access the members-only section.";
        $Response->Redirect("/login.asp");
      }# end if()
    }# end if()
  }# end Script_OnStart()

=head2 Script_OnEnd( )

Called right after processing for the script has finished, B<but not if an error occurred>
during the script's execution.

=head2 Script_OnError( $error )

Called right after processing for the script has finished, only if an error occurred.

The C<$error> passed in is a C<Devel::StackTrace> object.

This is a good place to insert code to email you about the error that occurred, or print out
a friendly error message to the client.

=head1 AUTHOR

John Drago L<jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut
