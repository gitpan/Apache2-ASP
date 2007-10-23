
package Apache2::ASP::Base;

use strict;
use warnings 'all';
use CGI ();
use Devel::StackTrace;

use Apache2::ASP::PageHandler;
use Apache2::ASP::Request;
use Apache2::ASP::Response;
use Apache2::ASP::Server;
use Apache2::ASP::GlobalASA;


#==============================================================================
sub new
{
  my ($class, $config) = @_;
  
  my $s = bless {
    config  => $config, #Apache2::ASP::Config->new(),
  }, ref($class) ? ref($class) : $class;
  
  return $s;
}# end new()


#==============================================================================
sub setup_request
{
  my ($s, $r, $q) = @_;
  # Init self:
  $s->{r}           = $r;
  $s->{q}           = $q ? $q : CGI->new();
  $s->{request}     = Apache2::ASP::Request->new( $s );
  $s->{response}    = Apache2::ASP::Response->new( $s );
  $s->{server}      = Apache2::ASP::Server->new( $s );

  $s->{application} = $s->{config}->application_state->manager->new( $s );
  $s->{session}     = $s->{config}->session_state->manager->new( $s );
  $s->{global_asa}  = $s->_global_asa_class->new( $s );
  
  # Init objects:
  
  # Who's going to handle this request?
  my $handler = $s->resolve_request_handler( $s->r->uri );
  $s->{handler} = $handler;
  
  return 1;
}# end setup_request()


#==============================================================================
sub execute
{
  my ($s, $is_subrequest, @args) = @_;
  
  if( ! $is_subrequest )
  {
    # Prevent multiple *OnStart events from being raised during the same request:
    $s->global_asa->can('Application_OnStart')->() 
      unless $s->application->{__did_init}++;
    $s->application->save;
    $s->global_asa->can('Session_OnStart')->()
      unless $s->session->{__did_init}++;
    $s->session->save;
    
    # Now that we've initialized our other objects, we can safely call Script_OnStart()
    $s->global_asa->can('Script_OnStart')->();
  }# end if()
  
  $s->{handler}->init_asp_objects( $s );
  
  eval {
    $s->run_handler( $s->{handler}, @args );
    $s->response->Flush;
  };
  if( $@ )
  {
    $s->global_asa->can('Script_OnError')->( Devel::StackTrace->new() );
    $s->response->Flush;
    return $s->response->{ApacheStatus} = 500;
  }# end if()
  
  if( ! $is_subrequest )
  {
    $s->global_asa->can('Script_OnEnd')->();
    
    # Using __lastPage instead of HTTP_REFERER prevents us from losing that data
    # after a JavaScript-initialized request:
    $s->session->{__lastPage} = $s->r->uri;
    $s->session->save();
    $s->application->save();
  }# end if()
  $s->response->Flush;
  
  return $s->response->{Status};
}# end execute()


#==============================================================================
sub run_handler
{
  my ($s, $handler, @args) = @_;
  
  $handler->before_run( $s, @args );
  $handler->run( $s, @args );
  $handler->after_run( $s, @args );
}# end run_handler()


#==============================================================================
sub _resolve_request_handler { resolve_request_handler(@_) };
sub resolve_request_handler
{
  my ($s, $uri) = @_;
  
  no warnings 'uninitialized';
  if( $uri =~ m/^\/handlers\// )
  {
    # (Try to) load up the handler:
    my ($handler) = $uri =~ m/^\/handlers\/([^\?]+)/;
    $handler =~ s/[^a-z0-9]/\//ig;
    eval { require "$handler.pm" };
    if( $@ )
    {
      # Failed to load the handler:
      die "Cannot load Handler '$handler': $@";
    }
    else
    {
      $handler =~ s/\//::/g;
      return $handler;
    }# end if()
  }
  else #if( $uri =~ m/\.asp$/ )
  {
    return 'Apache2::ASP::PageHandler';
  }# end if()
}# end _resolve_request_handler()


#==============================================================================
sub config      { $_[0]->{config}       }
sub r           { $_[0]->{r}            }
sub q           { $_[0]->{q}            }
sub session     { $_[0]->{session}      }
sub request     { $_[0]->{request}      }
sub response    { $_[0]->{response}     }
sub server      { $_[0]->{server}       }
sub application { $_[0]->{application}  }
sub global_asa  { $_[0]->{global_asa}   }


#==============================================================================
sub _global_asa_class
{
  my $s = shift;
  
  if( -f $s->config->www_root . '/GlobalASA.pm' )
  {
    require $s->config->www_root . '/GlobalASA.pm';
    return $s->config->application_name . '::GlobalASA';
  }
  else
  {
    return 'Apache2::ASP::GlobalASA';
  }# endif()
}# end _global_asa_class()


#==============================================================================
sub DESTROY
{
  my $s = shift;
  foreach(qw/ r q session application request response server global_asa /)
  {
    next unless $s->{ $_ };
    undef( $s->{ $_ } );
    delete( $s->{ $_ } );
  }# end foreach()
}# end DESTROY()

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::Base - Base class for ASP engines

=head1 SYNOPSIS

  package MyASP;
  
  use strict;
  use base 'Apache2::ASP::Base';
  
  # Use whatever Apache2::* and APR::* modules are necessary:
  
  sub handler : method
  {
    my ($class, $r) = @_;
    
    # We function best as an object:
    my $s = $class->SUPER::new( $ENV{APACHE2_ASP_CONFIG} );
    
    # What Apache2::ASP::Handler is going to handle this request?
    my $handler_class = $s->resolve_request_handler( $r->uri );
    if( $handler_class->isa('Apache2::ASP::UploadHandler') )
    {
      # We use the upload_hook functionality from Apache::Request
      # to process uploads:
      my $upload_hook = sub {
        my ($upload, $data) = @_;
        # Handle upload hook here...
      };
      $s->{q} = Apache2::ASP::CGI->new( $r, $upload_hook );
    }
    else
    {
      # Not an upload - normal CGI functionality will work fine:
      $s->{q} = Apache2::ASP::CGI->new( $r );
    }# end if()
    
    # Get our subref and execute it:
    my $handler = $s->setup_request( $r, $s->{q} );
    my $status = eval { $handler->( ) };
    if( $@ )
    {
      warn "ERROR AFTER CALLING \$handler->( ): $@";
      return $s->_handle_error( $@ );
    }# end if()
    
    # 0 = OK, everything else means errors of some kind:
    return $status;
  }# end handler()
  
  sub _handle_error
  {
    my ($s, $err) = @_;
    
    my $stack = Devel::StackTrace->new;
    warn $stack->as_string;
    $s->response->Clear();
    $s->global_asa->can('Script_OnError')->( $stack );
    
    return 500;
  }# end _handle_error()

=head1 DESCRIPTION

=head1 METHODS

=head2 new( $config )

Returns a new C<Apache2::ASP::Base> object using the C<Apache2::ASP::Config> object passed in as C<$config>.

=head2 setup_request( $r )

Creates a new request instance, based on the information about the request gleaned from C<$r> - an L<Apache2::RequestRec> object
(or something that behaves like one anyway).

Returns a subroutine reference.

Execute like:

  my $ref = $asp->setup_request( $r );
  
  # A normal request:
  $ref->( 0 );
  # or
  $ref->( );
  
  # A subrequest (i.e. as in the case of an include):
  $ref->( 1 );

=head2 config( )

Returns the current L<Apache2::ASP::Config> object.

=head2 r( )

Returns the L<Apache2::RequestRec> object.

=head2 q( )

Returns the L<Apache2::ASP::CGI> object.

=head2 session( )

Returns the current L<Apache2::ASP::SessionStateManager> object.

=head2 request( )

Returns the current L<Apache2::ASP::Request> object.

=head2 response( )

Returns the current L<Apache2::ASP::Response> object.

=head2 server( )

Returns the current L<Apache2::ASP::Server> object.

=head2 application( )

Returns the current L<Apache2::ASP::Application> object.

=head2 global_asa( )

Returns the L<Apache2::ASP::GlobalASA> object.

=head2 resolve_request_handler( $uri )

Returns the classname of the L<Apache2::ASP::Handler> subclass that will process the current HTTP request.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-ASP> to submit bug reports.

=head1 HOMEPAGE

Please visit the Apache2::ASP homepage at L<http://apache2-asp.no-ip.org/> to see examples
of Apache2::ASP in action.

=head1 AUTHOR

John Drago L<mailto:jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut
