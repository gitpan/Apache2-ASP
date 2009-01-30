
package Apache2::ASP::HTTPContext;

use strict;
use warnings 'all';
use Apache2::ASP::ConfigLoader;
use Apache2::ASP::Response;
use Apache2::ASP::Request;
use Apache2::ASP::Server;
use Carp qw( cluck confess );
use Scalar::Util 'weaken';
use HTTP::Headers;

our $instance;
our $ClassName = __PACKAGE__;

#==============================================================================
sub current
{
  my $class = shift;
  
  no strict 'refs';
  return ${"$ClassName\::instance"};
}# end current()


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  my $s = bless {
    %args,
    config  => $args{parent} ? undef : Apache2::ASP::ConfigLoader->load(),
  }, $class;
  $s->config->_init_inc();
  
  no strict 'refs';
  ${"$ClassName\::instance"} = $s;
}# end new()


#==============================================================================
sub setup_request
{
  my ($s, $requestrec, $cgi) = @_;
  
  if( ! $s->{parent} )
  {
    return unless $cgi;
    $cgi = $$cgi if ref($cgi) eq 'SCALAR';
    return unless $cgi;
    return if $s->{_is_setup}++;
  }# end if()
  
  $s->{r} = $requestrec;
  $s->{cgi} = $cgi;
#  my $headers = HTTP::Headers->new();
  
#  my $h = $s->r->headers_out;
#  while( my($k,$v) = each(%$h) )
#  {
#    $headers->push_header( $k => $v );
#  }# end while()

  $s->{headers_out} = HTTP::Headers->new();
  
  my $h = $s->r->headers_in;
  if( UNIVERSAL::isa($h, 'HTTP::Headers') )
  {
    $s->{headers_in} = $h;
  }
  else
  {
    my $headers_in = HTTP::Headers->new();
    while( my ($k,$v) = each(%$h) )
    {
      $headers_in->push_header( $k => $v );
    }# end while()
    $s->{headers_in} = $headers_in;
  }# end if()
  
  $s->{connection}  = $s->r->connection;

  $s->{handler} = $s->resolve_request_handler( $s->r->uri );
  $s->load_class( $s->{handler} );
  
  if( ! $s->{parent} )
  {
    $s->{response} = Apache2::ASP::Response->new();
    $s->{request}  = Apache2::ASP::Request->new();
    $s->{server}   = Apache2::ASP::Server->new();
  
    my $conns = $s->config->data_connections;
    my $app_manager = $conns->application->manager;
    $s->load_class( $app_manager );
    $s->{application} = $app_manager->new();
    my $session_manager = $conns->session->manager;
    $s->load_class( $session_manager );
    $s->{session} = $session_manager->new();
    
    # Make the global Stash object:
    $s->{stash} = { };
    
    $s->{global_asa} = $s->resolve_global_asa_class( );
    $s->{global_asa}->init_asp_objects( $s ) unless $s->{handler}->isa('Apache2::ASP::UploadHandler');
  }# end if()
  
  return 1;
}# end setup_request()


#==============================================================================
sub execute
{
  my ($s, $args) = @_;
  local $SIG{__DIE__} = \&Carp::confess;
  
  unless( $s->{parent} )
  {
    # Set up our @INC:
    $s->setup_inc();
    
    if( defined(my $res = $s->do_preinit) )
    {
      return $res;
    }# end if()
    
    # Set up and execute any matching request filters:
    foreach my $filter ( $s->resolve_request_filters() )
    {
      $s->load_class( $filter->class );
      $filter->class->init_asp_objects( $s );
      my $res = $s->handle_phase(sub{ $filter->class->new()->run( $s ) });
      if( defined($res) && $res != -1 )
      {
        return $res;
      }# end if()
    }# end foreach()
    
    my $res = $s->handle_phase( $s->global_asa->can('Script_OnStart') );
    return $res if defined( $res );
  }# end unless()
  
  eval {
    $s->load_class( $s->handler );
    $s->run_handler( $args );
  };
  if( $@ )
  {
    $s->server->{LastError} = $@;
    return $s->handle_error;
  }# end if()
  
  $s->response->Flush;
  my $res = $s->{parent} ? $s->response->Status : $s->end_request();
  if( $s->page && $s->page->directives->{OutputCache} && defined($s->{_cache_buffer}) )
  {
    if( $res == 200 || $res == 0 )
    {
      $s->page->_write_cache( \$s->{_cache_buffer} );
    }# end if()
  }# end if()
  
  $res = 0 if $res =~ m/^200/;
  return $res;
}# end execute()


#==============================================================================
sub run_handler
{
  my ($s, $args) = @_;
  
  my $handler = $s->handler->new();
  $handler->init_asp_objects( $s );
  $handler->before_run( $s, $args );
  if( ! $s->{did_end} )
  {
    $handler->run( $s, $args );
    $handler->after_run( $s, $args );
  }# end if()
}# end run_handler()


#==============================================================================
sub setup_inc
{
  my $s = shift;

  my $www_root = $s->config->web->www_root;
  push @INC, $www_root unless grep { $_ eq $www_root } @INC;
  my %libs = map { $_ => 1 } @INC;
  push @INC, grep { ! $libs{$_} } $s->config->system->libs;
}# end setup_inc()


#==============================================================================
sub resolve_request_filters
{
  my $s = shift;
  
  my ($uri) = split /\?/, $s->r->uri;
  return grep {
    if( my $pattern = $_->uri_match )
    {
      $uri =~ m/$pattern/
    }
    else
    {
      $uri eq $_->uri_equals;
    }# end if()
  } $s->config->web->request_filters;  
}# end resolve_request_filter()


#==============================================================================
sub do_preinit
{
  my $s = shift;
  
  
  unless( $s->_is_setup )
  {
    $s->setup_request( $Apache2::ASP::ModPerl::R, $Apache2::ASP::ModPerl::CGI );
  }# end unless()
  
  # Initialize the Server, Application and Session:
  unless( $s->application->{"__Server_Started$$"} )
  {
    my $res = $s->handle_phase(
      $s->global_asa->can('Server_OnStart')
    );
    $s->application->{"__Server_Started$$"}++ unless $@;
    return $s->end_request if $s->{did_end};
  }# end unless()
  
  unless( $s->application->{__Application_Started} )
  {
    my $res = $s->handle_phase(
      $s->global_asa->can('Application_OnStart')
    );
    $s->application->{__Application_Started}++ unless $@;
    return $s->end_request if $s->{did_end};
  }# end unless()
  
  unless( $s->session->{__Started} )
  {
    my $res = $s->handle_phase(
      $s->global_asa->can('Session_OnStart')
    );
    $s->session->{__Started}++ unless $@;
    return $s->end_request if $s->{did_end};
  }# end unless()
  
  return;
}# end do_preinit()


#==============================================================================
sub handle_phase
{
  my ($s, $ref) = @_;
  
  eval { $ref->( ) };
  if( $@ )
  {
    $s->handle_error;
  }# end if()
  
  # Undef on success:
  return $s->response->Status =~ m/^200/ ? undef : $s->response->Status;
}# end handle_phase()


#==============================================================================
sub handle_error
{
  my $s = shift;
  my $error = "$@";
  $s->response->Status( 500 );
  no strict 'refs';
#  if( defined(&{$s->global_asa . "::Script_OnError"}) )
#  {
#    eval { $s->global_asa->can('Script_OnError')->( $error ) };
#  }
#  else
#  {
    $s->response->Clear;
    my ($main, $title, $file, $line) = $error =~ m/^((.*?)\s(?:at|in)\s(.*?)\sline\s(\d+))/;
    $s->stash->{error} = {
      title       => $title,
      file        => $file,
      line        => $line,
      stacktrace  => $error,
    };
    warn "[Error: @{[ HTTP::Date::time2iso() ]}] $main\n";
    
    $s->load_class( $s->config->errors->error_handler );
    my $error_handler = $s->config->errors->error_handler->new();
    $error_handler->init_asp_objects( $s );
    eval { $error_handler->run( $s ) };
    confess $@ if $@;
#  }# end if()
  return $s->end_request;
}# end handle_error()


#==============================================================================
sub end_request
{
  my $s = shift;
  
  $s->handle_phase( $s->global_asa->can('Script_OnEnd') )
    unless $s->server->GetLastError;
  
  $s->response->End;
  $s->session->save;
  $s->application->save;
  my $res = $s->response->Status =~ m/^200/ ? 0 : $s->response->Status;
  
  return $res;
}# end end_request()


#==============================================================================
sub clone
{
  my $s = shift;
  
  return bless {%$s}, ref($s);
}# end clone()


#==============================================================================
sub get_prop
{
  my ($s, $prop) = @_;
  
  $s->{parent} ? $s->{parent}->get_prop($prop) : $s->{$prop};
}# end get_prop()

sub config       { $_[0]->get_prop('config') }
sub session      { $_[0]->get_prop('session')               }
sub server       { $_[0]->get_prop('server')                }
sub request      { $_[0]->get_prop('request')               }
sub response     { $_[0]->get_prop('response')              }
sub application  { $_[0]->get_prop('application')           }
sub stash        { $_[0]->get_prop('stash')                 }
sub global_asa   { $_[0]->get_prop('global_asa')            }
sub _is_setup    { $_[0]->get_prop('_is_setup')            }

sub r            { $_[0]->{r}                     }
sub cgi          { $_[0]->{cgi}                   }
sub handler      { $_[0]->{handler}               }
sub connection   { $_[0]->{connection}            }
sub page         { $_[0]->{page}                  }

# Need to get this figured out:
sub headers_in   { shift->get_prop('headers_in') }
sub send_headers
{
  my $s = shift;
  
  my $headers = $s->get_prop('headers_out');
  my $out = $s->get_prop('r')->headers_out;
  while( my ($k,$v) = each(%$headers) )
  {
    $out->{$k} = $v;
  }# end while()
  
  if( $s->get_prop('r')->can('send_headers') )
  {
    $s->get_prop('r')->headers_out->{$_} = $out->{$_} foreach keys(%$out);
    $s->get_prop('r')->send_headers;
  }
  else
  {
    $s->get_prop('r')->err_headers_out->add( $_ => $out->{$_} ) foreach keys(%$out);
    $s->get_prop('r')->headers_out->add( $_ => $out->{$_} ) foreach keys(%$out);
  }# end if()
  $s->{_did_send_headers}++;
}# end send_headers()

sub headers_out  { shift->get_prop('headers_out') }
sub content_type { shift->get_prop('r')->content_type( @_ ) }
sub print
{
  my ($s, $str) = @_;
  $s->{_cache_buffer} .= $str;
  $s->r->print( $str );
}# end print()
sub rflush       { shift->{r}->rflush( @_ )       }
sub did_send_headers { shift->get_prop('_did_send_headers') }


#==============================================================================
sub resolve_request_handler
{
  my ($s, $uri) = @_;
  
  ($uri) = split /\?/, $uri;
  if( $uri =~ m/^\/handlers\// )
  {
    (my $handler = $uri) =~ s/^\/handlers\///;
    $handler =~ s/[^a-z0-9_]/::/gi;
    $s->load_class( $handler );
    return $handler;
  }
  else #if( $uri =~ m/\.asp$/ )
  {
    my $handler = 'Apache2::ASP::ASPHandler';
    $s->load_class( $handler );
    return $handler;
  }# end if()
}# end resolve_request_handler()


#==============================================================================
sub resolve_global_asa_class
{
  my $s = shift;
  
  my $file = $s->config->web->www_root . '/GlobalASA.pm';
  my $class;
  if( -f $file )
  {
    $class = $s->config->web->application_name . '::GlobalASA';
    eval { require $file unless $INC{$file} };
    confess $@ if $@;
  }
  else
  {
    $class = 'Apache2::ASP::GlobalASA';
    $s->load_class( $class );
  }# end if()
  
  return $class;
}# end resolve_global_asa_class()


#==============================================================================
sub load_class
{
  my ($s, $class) = @_;
  
  (my $file = "$class.pm") =~ s/::/\//g;
  eval { require $file unless $INC{$file}; 1 } or confess "Cannot load $class: $@";
}# end load_class()


#==============================================================================
sub DESTROY
{
  my $s = shift;
  undef(%$s);
}# end DESTROY()

1;# return true:


=pod

=head1 NAME

Apache2::ASP::HTTPContext - Contextual execution harness for ASP scripts.

=head1 SYNOPSIS

  # Get the original mod_perl '$r' object:
  my Apache2::RequestRec $r = $context->r;
  
  # Get the other traditional ASP objects:
  my $Config      = $context->config;
  my $Request     = $context->request;
  my $Response    = $context->response;
  my $Server      = $context->server;
  my $Session     = $context->session;
  my $Application = $context->application;
  
  # Get the current context object from anywhere within your application:
  my $context = Apache2::ASP::HTTPContext->current;

=head1 DESCRIPTION

=head1 STATIC PROPERTIES

=head2 current

Returns the "current" HTTPContext instance.

=head1 PUBLIC PROPERTIES

=head2 r

Returns the current Apache2::RequestRec object.

B<NOTE>: while in "API" or "Testing" mode, C<r> returns the current 
L<Apache2::ASP::Mock::RequestRec> object.

=head2 config

Returns the current L<Apache2::ASP::Config> object.

=head2 request

Returns the current L<Apache2::ASP::Request> object.

=head2 response

Returns the current L<Apache2::ASP::Response> object.

=head2 server

Returns the current L<Apache2::ASP::Server> object.

=head2 session

Returns the current L<Apache2::ASP::Session> object.

=head2 application

Returns the current L<Apache2::ASP::Application> object.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-ASP> to submit bug reports.

=head1 HOMEPAGE

Please visit the Apache2::ASP homepage at L<http://www.devstack.com/> to see examples
of Apache2::ASP in action.

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 COPYRIGHT

Copyright 2008 John Drago.  All rights reserved.

=head1 LICENSE

This software is Free software and is licensed under the same terms as perl itself.

=cut

