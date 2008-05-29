
package Apache2::ASP::GlobalASA;

use strict;
use warnings 'all';

use vars qw($Request $Response $Session $Application $Server $Form $Config);


#==============================================================================
sub new
{
  my ($class, $asp) = @_;
  my $s = bless {
#    asp => $asp
  }, $class;
  
  $s->_init_globals( $asp );
  return $s;
}# end new()


#==============================================================================
sub _init_globals
{
  my ($s, $asp) = @_;
  
  no strict 'refs';
  my $class = ref($s);
  $Request      = ${"$class\::Request"}     = $asp->request;
  $Response     = ${"$class\::Response"}    = $asp->response;
  $Session      = ${"$class\::Session"}     = $asp->session;
  $Form         = ${"$class\::Form"}        = $asp->request->Form;
  $Application  = ${"$class\::Application"} = $asp->application;
  $Server       = ${"$class\::Server"}      = $asp->server;
  $Config       = ${"$class\::Config"}      = $asp->config;
  
  return 1;
}# end _init_globals()


#==============================================================================
sub Application_OnStart
{
  
}# end Application_OnStart()


#==============================================================================
sub Server_OnStart
{
  
}# end Server_OnStart()


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
sub DESTROY
{
  my $s = shift;
  delete($s->{$_}) foreach keys(%$s);
}# end DESTROY()

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
    my $err;
    
    # Log the error:
    warn "[" . localtime() . "] An error has occurred: " . $err;
    
    # Print something friendly:
    $Response->Write("Sorry for the inconvenience.  Please try again later.");
    
    # Email the webmaster:
    $Server->Mail(
      To      => 'me@mydomain.com',
      Subject => '500 Server error',
      Message => "Please look at the following error:\n\n" . $err
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

=head2 Server_OnStart( )

Executes once per Apache child, before servicing the first request that Apache child
processes.

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

The C<$error> passed in is the current value of C<$@>.

This is a good place to insert code to email you about the error that occurred, or print out
a friendly error message to the client.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-ASP> to submit bug reports.

=head1 HOMEPAGE

Please visit the Apache2::ASP homepage at L<http://www.devstack.com/> to see examples
of Apache2::ASP in action.

=head1 AUTHOR

John Drago L<jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut
