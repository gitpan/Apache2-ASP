
package Apache2::ASP;

our $VERSION = 0.02;

use strict;
use warnings 'all';
use CGI::Apache2::Wrapper ();
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Directive ();
use Apache2::Connection ();
use Apache2::SubRequest ();
use Devel::StackTrace;

use Apache2::ASP::Parser;
use Apache2::ASP::Request;
use Apache2::ASP::Response;
use Apache2::ASP::Server;
use Apache2::ASP::Application;
use Apache2::ASP::Session;
use Apache2::ASP::GlobalASA;
use Apache2::ASP::MockRequest;

use vars qw(
  $Session $Request $Response $Server $Application $GlobalASA
);


#==============================================================================
sub handler : method
{
  my ($s, $r) = @_;
  $s = bless {r => $r}, ref($s) || $s;
  
  my $q = CGI::Apache2::Wrapper->new( $r );
  $s->{q} = $q;
  
  return $s->_handle_request( $r, $q );
}# end handler()


#==============================================================================
sub _handle_request
{
  my ($s, $r, $q) = @_;
  
  my $filename = $r->filename;
  
  if( -f $filename )
  {
    if( $filename =~ m/\.asp$/ )
    {
      return $s->_handle_dynamic_request( $r, $q, $filename );
    }
    else
    {
      return $s->_handle_static_request( $r, $q, $filename );
    }# end if()
  }
  elsif( -d $filename )
  {
    # See if there is an index.asp here:
    if( -f $filename . "index.asp" )
    {
      $r->filename( $filename . "index.asp" );
      return $s->handler( $r );
    }
    else
    {
      return 403;
    }# end if()
  }# end if()
  
}# end _handle_request()


#==============================================================================
sub _handle_static_request
{
  my ($s, $r, $q, $filename) = @_;
  
  return $r->sendfile( $filename );
}# end _handle_static_request()


#==============================================================================
sub _handle_dynamic_request
{
  my ($s, $r, $q, $filename) = @_;

  # Read the file:
  open my $ifh, '<', $filename
    or die "Cannot open file '$filename': $!";
  local $/;
  my $script_contents = <$ifh>;
  close( $ifh );

  # Standard ASP objects:
  $Session     = Apache2::ASP::Session->new( undef, $r );
  $Request     = Apache2::ASP::Request->new( $r, $q );
  $Response    = Apache2::ASP::Response->new( $r, $q, $s );
  $Server      = Apache2::ASP::Server->new( $r, $q, \$script_contents );
  $Application = Apache2::ASP::Application->new( );
  
  # Setup the global.asa:
  $GlobalASA = $s->_setup_globalASA( $r );
  $GlobalASA->init_globals(
    $Request,
    $Response,
    $Session,
    scalar( $Request->Form ),
    $Application,
    $Server
  ) or die "Cannot init globals!";
  $s->{_global_asa} = $GlobalASA;
  
  # Prepare the code for parsing:
  $GlobalASA->Script_OnParse();
  
  # Init the Session:
  if( ! $Session->{__aspinit} )
  {
    $GlobalASA->Session_OnStart();
    $Session->{__aspinit} = 1;
  }# end if()
  
  $s->execute_script( \$script_contents );
  
  my $status = $Response->{ApacheStatus};
  $Session->DESTROY;
  $Server->DESTROY;
  $Application->DESTROY;
  $Response->Flush;
  $Response->DESTROY;
  $Request->DESTROY;
  
  return $status;
}# end _handle_dynamic_request()


#==============================================================================
# Used for TrapInclude only:
sub handle_sub_request
{
  my ($s, $script_contents, @args) = @_;
  
  my $r = Apache2::ASP::MockRequest->new();

  # Standard ASP objects:
  my $Session     = Apache2::ASP::Session->new( undef, $r );
  my $Request     = Apache2::ASP::Request->new( $r, $s->{q} );
  my $Response    = Apache2::ASP::Response->new( $r, $s->{q}, $s );
  my $Server      = Apache2::ASP::Server->new( $r, $s->{q}, \$script_contents );
  my $Application = Apache2::ASP::Application->new( );
  
  # Setup the global.asa:
  my $GlobalASA = $s->_setup_globalASA( $r );
  $GlobalASA->init_globals(
    $Request,
    $Response,
    $Session,
    scalar( $Request->Form ),
    $Application,
    $Server
  ) or die "Cannot init globals!";
  local($s->{_global_asa}) = $GlobalASA;
  
  # Prepare the code for parsing:
  $GlobalASA->Script_OnParse();
  
  # Init the Session:
  if( ! $Session->{__aspinit} )
  {
    $GlobalASA->Session_OnStart();
    $Session->{__aspinit} = 1;
  }# end if()
  
  # Init the Script:
  $GlobalASA->Script_OnStart();
  my $coderef = $s->_compile_script( $Server->{ScriptRef} );
  
  eval { $coderef->( @args ) };
  if( $@ )
  {
    # Handle the execution error:
    $s->_handle_error( $@ );
  }# end if()
  
  return $r->{_buffer};
}# end handle_sub_request()


#==============================================================================
sub execute_script
{
  my ($s, $scriptref, @args) = @_;
  $Server->{ScriptRef} = $scriptref;

  # Init the Script:
  $GlobalASA->Script_OnStart();
  my $coderef = $s->_compile_script( $Server->{ScriptRef} );
  if( $@ )
  {
    # An error - handle it:
    $s->_handle_error( $@ );
  }# end if()
  
  # Execute the script:
  eval { $coderef->( @args ) };
  if( $@ )
  {
    # Handle the execution error:
    $s->_handle_error( $@ );
  }# end if()
  
  # Follow the GlobalASA rules:
  $GlobalASA->Script_OnEnd()
    unless $@;
}# end execute_script()


#==============================================================================
sub _setup_globalASA
{
  my ($s, $r);
  my $tree = Apache2::Directive::conftree();
  
  my $docroot;
  # Check out our VirtualHost config (if it exists):
  if( my $vhost = $tree->lookup('VirtualHost') )
  {
    $docroot = $tree->lookup('VirtualHost')->{DocumentRoot};
  }
  else
  {
    # Default to the global DocumentRoot:
    $docroot = $tree->lookup('DocumentRoot');
  }# end if()
  
  $docroot =~ s/"//g;
  
  my $file = "$docroot/GlobalASA.pm";
  if( -f $file )
  {
    if( $INC{'GlobalASA.pm'} ne $file )
    {
      push @INC, $docroot;
      require GlobalASA;
    }# end if()
    return GlobalASA->new();
  }
  else
  {
    return Apache2::ASP::GlobalASA->new();
  }# end if()
}# end _setup_globalasa()


#==============================================================================
sub _compile_script
{
  my ($s, $ref) = @_;

  my $parsed = Apache2::ASP::Parser->parse_string( $$ref );
  
  my $pkg = $s->{r}->filename;
  $pkg =~ s/[^a-zA-Z0-9_]/_/g;
  
  my $stub = <<EOF;
package $pkg; use vars qw(\$Request \$Response \$Server \$Session \$Form \$Application);sub Process {$parsed
\$Response->Flush;
};


1;
EOF

  no warnings 'redefine';
  eval $stub;
  if( $@ )
  {
    # Handle the error:
    $s->_handle_error( $@ );
  }# end if()
  no strict 'refs';
  ${"$pkg\::Request"}     = $Request;
  ${"$pkg\::Response"}    = $Response;
  ${"$pkg\::Server"}      = $Server;
  ${"$pkg\::Session"}     = $Session;
  ${"$pkg\::Form"}        = $Request->Form;
  ${"$pkg\::Application"} = $Application;
  
  # Return the subref:
  return $pkg->can('Process');
}# end _asp_stub()


#==============================================================================
sub _handle_error
{
  my ($s, $err) = @_;
  
  my $stack = Devel::StackTrace->new;
  
  $Response->Clear();
  $GlobalASA->Script_OnError( $stack );
}# end _handle_error()


1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP - ASP for a mod_perl2 environment.

=head1 SYNOPSIS

  <html>
    <body>
      <%= "Hello, World!" %>
      <br>
      <%
        for( 1...10 ) {
          $Response->Write( "Hello from ASP ($_)<br>" );
        }
      %>
    </body>
  </html>

=head1 DESCRIPTION

Apache2::ASP is a new implementation of the ASP web programming for the mod_perl2 
environment.  Its aim is high performance, stability, scalability and ease of use.

If you have used L<Apache::ASP> already then you are already familiar with the basic
idea of ASP under Apache.

=head1 INTRODUCTION

=head2 What is Apache2::ASP?

Apache2::ASP is a web programming environment that helps simplify 
web programming with Perl under mod_perl2.  Apache2::ASP allows 
you to easily embed Perl into web pages using the "<%" and "%>"
tags that are familiar to anyone who has used ASP or JSP in the past.

=head2 What does Apache2::ASP offer?

Apache2::ASP offers programmers the ability to program web pages without
spending time on details like session state management, file uploads
or template systems.

=head1 ASP OBJECTS

Like other ASP web programming environments, Apache2::ASP provides the
following global objects:

=head2 $Request

Represents the incoming HTTP request.  Has methods to handle form data,
file uploads, read cookies, etc.

Learn more by reading the L<Apache2::ASP::Request> documentation.

=head2 $Response

Represents the outbound HTTP communication to the client.  Has methods to
send content, redirect, set cookies, etc.

Learn more by reading the L<Apache2::ASP::Response> documentation.

=head2 $Session

Represents data that should persist beyond the lifetime of a single request.
For example, the user's logged in state, user id, etc.

The contents of the C<$Session> object are stored within an SQL database.

Learn more by reading the L<Apache2::ASP::Session> documentation.

=head2 $Server

Represents the webserver itself and offers several utility methods that don't
fit anywhere else.

Learn more by reading the L<Apache2::ASP::Server> documentation.

=head2 $Application

Represents data that should be shared and persisted throughout the entire 
web application.  For example, database connection strings, the number of active
users, etc.

The contents of the C<$Application> object are stored within an SQL database.

Learn more by reading the L<Apache2::ASP::Application> documentation.

=head1 INSTALLATION

  % perl Makefile.PL
  % make
  % make test
  % make install

Then, in your httpd.conf:
  
  # Declare this important variable:
  PerlSetEnv APACHE2_APPLICATION_ROOT /path/to/your/website

  # Needed for CGI::Apache2::Wrapper to work properly:
  LoadModule apreq_module    /usr/local/apache2/modules/mod_apreq2.so
  
  # Set the directory index:
  DirectoryIndex index.asp
  
  # Load up some important modules:
  PerlModule Apache::DBI
  PerlModule DBI
  PerlModule DBD::mysql # or whatever database you will keep your session data in
  PerlModule CGI::Apache2::Wrapper
  PerlModule Apache2::ASP
  PerlModule Apache2::Directive
  PerlModule Apache2::RequestRec
  PerlModule Apache2::RequestIO
  PerlModule Apache2::Connection
  PerlModule Apache2::SubRequest
  
  # All *.asp files are handled by Apache2::ASP
  <Files ~ (\.asp$)>
    SetHandler      perl-script
    PerlHandler     Apache2::ASP
  </Files>

Then, in C</path/to/your/website/conf> add the file C<apache2-asp-config.xml>.
It will contain data like this:

  <apache2-asp-config>
    <db_user>mydbusername</db_user>
    <db_pass>secret!password</db_pass>
    <db_driver>mysql</db_driver>
    <db_name>my_session_database</db_name>
    <db_host>localhost</db_host>
    <session_cookie_domain>.mywebsite.com</session_cookie_domain>
    <session_cookie_name>session-id</session_cookie_name>
  </apache2-asp-config>

Then, in your database, create a table with the following structure:

  CREATE TABLE sessions (
    session_id CHAR(32) PRIMARY KEY NOT NULL,
    session_data BLOB,
    created_on DATETIME,
    modified_on DATETIME
  );

Also create a table with the following structure:

  CREATE TABLE asp_applications (
    application_id VARCHAR(100) PRIMARY KEY NOT NULL,
    application_data BLOB
  );

Simply restart Apache and installation is complete.  Now you need some ASP scripts.

If your website is in C</var/www/html> then create a file "C<index.asp>" in C</var/www/html>.

Your C<index.asp> could contain something like the following:

  <html>
    <body>
      <%= "Hello, World!" %>
      <br>
      <%
        for( 1...10 ) {
          $Response->Write( "Hello from ASP ($_)<br>" );
        }
      %>
    </body>
  </html>

Then point your browser to C<http://yoursite.com/index.asp> and see what you get.

If everything was configured correctly, the output would look like:

  Hello, World! 
  Hello from ASP (1)
  Hello from ASP (2)
  Hello from ASP (3)
  Hello from ASP (4)
  Hello from ASP (5)
  Hello from ASP (6)
  Hello from ASP (7)
  Hello from ASP (8)
  Hello from ASP (9)
  Hello from ASP (10)

If you get an error instead, check out your error log to find out why.

=head2 Directory Structure

You might be wondering, "What does the directory structure for an Apache2::ASP website look like?"

Well, it looks like this:

  .
  |-- conf
  |   |-- apache2-asp-config.xml
  |   `-- httpd.conf
  `-- www
      |-- GlobalASA.pm
      `-- index.asp

=head1 AUTHOR

John Drago L<jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut
