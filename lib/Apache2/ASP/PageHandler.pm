
package Apache2::ASP::PageHandler;

use strict;
use warnings 'all';
use base 'Apache2::ASP::Handler';
use Apache2::ASP::Parser;

our %ASP_Times = ();

#==============================================================================
sub run
{
  my ($class, $asp, @args) = @_;
  
  my $s = bless {
    asp => $asp,
  }, $class;
  
  # Turn the uri into a package name:
  my $package_name = $s->{asp}->r->uri;
  $package_name =~ s/[^a-z_0-9]/_/ig;
  $package_name =~ s/^_+//;
  my $full_package_name = $s->{asp}->config->application_name . '::' . $package_name;
  
  # Make sure a directory for this application exists under the PAGE_CACHE:
  my $dir = $asp->config->page_cache_root . '/' . $s->{asp}->config->application_name;
  mkdir($dir) unless -d $dir;
  
  # Save ourselves some typing by using friendly variable names:
  my $asp_filename = $s->{asp}->config->www_root . $s->{asp}->{r}->uri;
  my $package_filename = $dir . '/' . $package_name . '.pm';
  
  # Make sure the ASP exists in the first place:
  if( ! $s->asp_exists( $asp_filename ) )
  {
    $s->{asp}->response->{Status} = 404;
    return;
  }# end if()
  
  # Create or recreate the *.pm file?
  if( $s->pm_exists($package_filename) )
  {
    # *.pm exists:
    if( $asp->config->do_reload_on_script_change )
    {
      # See if the *.asp is newer:
      if( $s->asp_has_changed( $package_filename, $asp_filename, $full_package_name ) )
      {
        # *.asp script has changed - recompile the *.pm:
        $s->compile_asp( $package_filename, $asp_filename, $full_package_name );
        
        # Force Perl to reload the package when we require() it:
        delete( $INC{$package_filename} );
        no strict 'refs';
        undef ${"$full_package_name\::TIMESTAMP"};
      }# end if()
    }# end if()
  }
  else
  {
    # *.pm doesn't exist - create it:
    $s->compile_asp( $package_filename, $asp_filename, $full_package_name );
  }# end if()

  # Runtime import of the newly-created class:
  eval { require $package_filename };
  if( $@ )
  {
    # This is raised when a compilation error occurs:
    die "Cannot load '" . $s->{asp}->{r}->uri . "': $@";
  }# end if()
  
  # Set up the classic ASP variables we've all come to love:
  $s->init_page_class( $full_package_name );
  
  # Handle the request:
  $full_package_name->process_request( @args );
  $s->{asp}->response->Flush;
  
  # Done!
  0;
}# end run()


#==============================================================================
sub asp_has_changed
{
  my ($s, $package_filename, $asp_filename, $full_package_name) = @_;
  
  eval { require $package_filename };
  return 1 if $@;
  no strict 'refs';
  if( my $pm_time = ${"$full_package_name\::TIMESTAMP"} )
  {
    # We use 'mtime' - see `perldoc stat` for details:
    my $asp_time = (stat($asp_filename))[9];
    return $asp_time > $pm_time;
  }
  else
  {
    # We haven't yet loaded the class - just return true:
    return 1;
  }# end if()
}# end asp_has_changed()


#==============================================================================
sub pm_exists
{
  my ($s, $package_filename) = @_;
  
  return -f $package_filename;
}# end pm_exists()


#==============================================================================
sub asp_exists
{
  my ($s, $asp_filename) = @_;
  
  return -f $asp_filename;
}# end pm_exists()


#==============================================================================
sub compile_asp
{
  my ($s, $package_filename, $asp_filename, $full_package_name) = @_;
  
  # Enable Script_OnParse() functionality:
  open my $ifh, '<', $asp_filename
    or die "Cannot open '$asp_filename' for reading: $!";
  local $/ = undef;
  my $raw_code = <$ifh>;
  close($ifh);
  $s->{asp}->global_asa->can('Script_OnParse')->( \$raw_code );
  
  # Now that the code has been prepared for parsing...
  my $code = Apache2::ASP::Parser->parse_string( $raw_code );
  
  # Create a regular Perl module and write it to disk in the PAGE_CACHE directory:
  my $page_code = $s->asp_to_package( $code, $full_package_name );
  open my $ofh, '>', $package_filename
    or die "Cannot open '$package_filename' for writing: $!";
  print $ofh $page_code;
  close($ofh);
  
  $ASP_Times{$asp_filename} = (stat($asp_filename))[9];
  
  return 1;
}# end compile_asp()


#==============================================================================
sub init_page_class
{
  my ($s, $full_package_name) = @_;
  
  no strict 'refs';
  ${"$full_package_name\::Session"}      = $s->{asp}->session;
  ${"$full_package_name\::Server"}       = $s->{asp}->server;
  ${"$full_package_name\::Request"}      = $s->{asp}->request;
  ${"$full_package_name\::Response"}     = $s->{asp}->response;
  ${"$full_package_name\::Form"}         = $s->{asp}->request->Form;
  ${"$full_package_name\::Application"}  = $s->{asp}->application;
  ${"$full_package_name\::Config"}       = $s->{asp}->config;
  
  return 1;
}# end init_page_class()


#==============================================================================
sub asp_to_package
{
  my ($s, $code, $package_name) = @_;
  my $now = localtime();
  my $timestamp = time();
  my $package_code = <<EOF;
#==============================================================================
# THIS FILE WAS AUTOMATICALLY GENERATED BY Apache2::ASP::PageHandler.
# TIMESTAMP: $now
# CHANGES TO THIS FILE WILL BE OVERWRITTEN WHEN THE ASP SCRIPT IS CHANGED
#==============================================================================
package $package_name;
use strict;
use warnings 'all';
no warnings 'redefine';
use base 'Apache2::ASP::PageHandler';
use vars qw(
  \$Session    \$Server
  \$Request    \$Response
  \$Form       \$Application
  \$Config
);
our \$TIMESTAMP = $timestamp;
#line 1
sub process_request { $code
}
1;# return true:

=pod

=head2 process_request( )

=cut
EOF

  return $package_code;
}# # end asp_to_package()

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::PageHandler - Handler class for *.asp scripts

=head1 SYNOPSIS

  # Execute the page that the $asp object is pointing at, 
  # and pass in some args to that page:
  Apache2::ASP::PageHandler->run($asp, @args);
  
  if( Apache2::ASP::PageHandler->asp_has_changed( $asp_filename ) ) { ... }
  
  if( Apache2::ASP::PageHandler->asp_exists( $asp_filename ) ) { ... }
  
  if( Apache2::ASP::PageHandler->pm_exists( $pm_filename ) ) { ... }
  
  Apache2::ASP::PageHandler->compile_asp( $package_filename, $asp_filename, $pm_filename );
  
  my $perl_module_code = Apache2::ASP::PageHandler->asp_to_package( $code, $package_name );
  
=head1 DESCRIPTION

This class is the subclass of L<Apache2::ASP::Handler> that processes all requests for ASP scripts.

=head1 HOW DOES IT WORK?

It works by converting your ASP code into a Perl module, then loading that module up like any other Perl module.

Once loaded, your code is executed (like any other Perl module) and the result is printed to the client.

If your ASP script contains code like this:

  <%
    $Response->Write("Hello, World!");
    $Response->End;
  %>

You will end up with a file inside of C<$ENV{APACHE2_ASP_APPLICATION_ROOT}/PAGE_CACHE/[ApplicationName]/hello_world_asp.pm>
containing code like this:

  #==============================================================================
  # THIS FILE WAS AUTOMATICALLY GENERATED BY Apache2::ASP::PageHandler.
  # TIMESTAMP: Wed Jun 20 23:42:53 2007
  # CHANGES TO THIS FILE WILL BE OVERWRITTEN WHEN THE ASP SCRIPT IS CHANGED
  #==============================================================================
  package DefaultApp::index_asp;
  use strict;
  use warnings 'all';
  no warnings 'redefine';
  use base 'Apache2::ASP::PageHandler';
  use vars qw(
    $Session    $Server
    $Request    $Response
    $Form       $Application
    $Config
  );
  #line 1
  sub process_request { $Response->Write(q~~);
    $Response->Write("Hello, World!");
    return;
  ;$Response->Write(q~
  ~);
  }
  1;# return true:
  
  =pod
  
  =head2 process_request( )
  
  =cut

Your code ends up inside of sub <process_request()> - so B<do not declare any subroutines in your ASP script>.
Doing so may end up causing a memory leak.

=head1 METHODS

=head2 run( $asp [, @args ] )

Executes whatever page the $asp->r->uri is pointed at.

Passes in C<@args> to the ASP script upon execution as C<@_>.

=head2 asp_has_changed( $pm_filename, $asp_filename )

Returns true if C<$asp_filename> was last modified after C<$pm_filename> was.

=head2 pm_exists( $pm_filename )

Returns true if C<$pm_filename> exists.

=head2 asp_exists( $asp_filename )

Returns true if C<$asp_filename> exists.

=head2 compile_asp( $pm_filename, $asp_filename, $full_package_name )

Compiles the C<$asp_filename> into a package named C<$full_package_name> and writes the
resulting Perl code to C<$pm_filename>.

=head2 init_page_class( $full_package_name )

Initializes the ASP objects in the namespace indicated by C<$full_package_name>.

Classic ASP objects include $Session, $Server, $Application, $Request, $Response, $Form and $Config.

=head2 asp_to_package( $code, $package_name )

Places the C<$code> into a real Perl module named C<$package_name>, then returns the
resulting Perl code.

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
