
package Apache2::ASP::Handler;

use strict;
use warnings 'all';

use vars qw(
  %modes
  $Request $Response
  $Session $Application
  $Server $Form
  $Config
);

#==============================================================================
sub run
{
  my ($s, $asp, @args) = @_;
  
  # Call our extension hooks:
  if( my $mode = $Request->Form('mode') )
  {
    if( defined($modes{ $mode }) )
    {
      return $modes{$mode}->( @_ );
    }
    else
    {
      $asp->response->Write("Unknown mode '$mode'.");
    }# end if()
  }
  else
  {
    $asp->response->Write("This is the default handler response.");
  }# end if()
  
  $asp->response->Flush;
}# end run()


#==============================================================================
sub init_asp_objects
{
  my ($s, $asp) = @_;
  
  $Session      = $asp->session;
  $Server       = $asp->server;
  $Request      = $asp->request;
  $Response     = $asp->response;
  $Form         = $asp->request->Form;
  $Application  = $asp->application;
  $Config       = $asp->config;
  
  no strict 'refs';
  foreach my $pkg( ( $s, @{"$s\::ISA"} ) )
  {
    ${"$pkg\::Session"}     = $Session;
    ${"$pkg\::Server"}      = $Server;
    ${"$pkg\::Request"}     = $Request;
    ${"$pkg\::Response"}    = $Response;
    ${"$pkg\::Form"}        = $Form;
    ${"$pkg\::Application"} = $Application;
    ${"$pkg\::Config"}      = $Config;
  }# end foreach()
  
  return 1;
}# end init_page_class()


#==============================================================================
sub register_mode
{
  my ($s, %info) = @_;
  
  $modes{ $info{name} } = $info{handler};
}# end register_mode()

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::Handler - Base class for all Apache2::ASP handlers

=head1 SYNOPSIS

  package MyHandler;
  
  use strict;
  use base 'Apache2::ASP::Handler';
  
  sub run {
    my ($s, $asp, @args) = @_;
    
    $asp->response->Write("Hello, world!.");
  }# end process_request()
  
  1;# return true:

Access C<MyHandler> via the URL C</handlers/MyHandler> on your website.

=head1 DESCRIPTION

Apache2::ASP::Handler offers an "in-between" ASP environment in which there 
is no Perl embedded within HTML (via <% and %> tags) but you still get
the ASP objects (C<$Request>, C<$Response>, C<$Session>, C<$Server> and C<$Application>).

Handlers are useful for things like form processing when no HTML content is
sent back to the client (because the client is redirected to another ASP instead).

=head1 METHODS

The following methods are intended for subclasses of C<Apache2::ASP::Handler>.

=head2 run( $self, $asp, @args)

Works just like the example in the synopsis.

=head2 register_mode( %args )

Allows your Handler class to handle "mode=xxx" requests for other Handlers.

Example:

  package MyHandler;
  
  use base 'SomeDefaultHandler';
  
  __PACKAGE__->register_mode(
    name    => 'mymode',
    handler => \&do_mymode,
  );
  
  # Accessible via URLs such as /handler/SomeDefaultHandler?mode=mymode
  sub do_mymode
  {
    my ($Session, $Request, $Response, $Server, $Application) = @_;
    
    # ... do stuff ...
    $Response->Write("mymode is successful!");
  }# end do_mymode()

Any call to C</media/file123.gif?mode=mymode> will execute your C<do_mymode()> method.

This is useful for generating image thumbnails - i.e. C</media/file123.gif?mode=thumb&max_w=100&max_h=80>

The rest is left as an exercise for the reader.

=head1 AUTHOR

John Drago L<jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut
