
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

#==============================================================================
sub current
{
  my $class = shift;

  return $instance;
}# end current()


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  my $s = bless {
    %args,
    config  => $args{parent} ? $args{parent}->{config} : Apache2::ASP::ConfigLoader->load(),
  }, $class;
  
  $instance = $s;
}# end new()


#==============================================================================
sub setup_request
{
  my ($s, $requestrec, $cgi) = @_;
  
  $s->{r} = $requestrec;
  $s->{cgi} = $cgi;
  my $headers = HTTP::Headers->new();
  my $h = $s->{r}->headers_out;
  while( my($k,$v) = each(%$h) )
  {
    $headers->push_header( $k => $v );
  }# end while()
  $s->{headers_out} = $headers;
  
  $h = $s->{r}->headers_in;
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
  
  $s->{connection}  = $s->{r}->connection;
  
  $s->{response} = Apache2::ASP::Response->new( context => $s );
  $s->{request}  = $s->{parent} ? $s->{parent}->{request} : Apache2::ASP::Request->new( context => $s );
  $s->{server}   = $s->{parent} ? $s->{parent}->{server} : Apache2::ASP::Server->new( context => $s );
  
  my $conns = $s->config->data_connections;
  my $app_manager = $conns->application->manager;
  $s->load_class( $app_manager );
  $s->{application} = $s->{parent} ? $s->{parent}->{application} : $app_manager->new( context => $s );
  my $session_manager = $conns->session->manager;
  $s->load_class( $session_manager );
  $s->{session} = $s->{parent} ? $s->{parent}->{session} : $session_manager->new( context => $s );
  
  # Make the global Stash object:
  $s->{stash} = $s->{parent} ? $s->{parent}->{stash} : { };
  
  # Fire up the GlobalASA:
  $s->{global_asa} = $s->resolve_global_asa_class( );
  $s->{global_asa}->init_asp_objects( $s );
  
  $s->{handler} = $s->resolve_request_handler( $s->r->uri );
  $s->handler->init_asp_objects( $s );
  
  return 1;
}# end setup_request()


#==============================================================================
sub execute
{
  my ($s, $args) = @_;
  
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
    $s->handler->init_asp_objects( $s );
    $s->handler->new()->run( $s, $args );
  };
  $s->server->{LastError} = $@ if $@;
  return $s->handle_error if $@;
  
  $s->response->Flush;
  my $res = $s->{parent} ? $s->response->Status : $s->end_request();
  if( $s->page && $s->page->directives->{OutputCache} && defined($s->{_cache_buffer}) )
  {
    if( $res == 200 || $res == 0 )
    {
      $s->page->_write_cache( \$s->{_cache_buffer} );
    }# end if()
  }# end if()
  
  return $res;
}# end execute()


#==============================================================================
sub setup_inc
{
  my $s = shift;

  my $www_root = $s->config->web->www_root;
  push @INC, $www_root unless grep { $_ eq $www_root } @INC;
  foreach my $lib ( $s->config->system->libs )
  {
    push @INC, $lib unless grep { $_ eq $lib } @INC;
  }# end foreach()
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
  
  # Initialize the Server, Application and Session:
  unless( $s->application->{"__Server_Started$$"} )
  {
    my $res = $s->handle_phase(
      $s->global_asa->can('Server_OnStart')
    );
    $s->application->{"__Server_Started$$"}++ unless $@;
    return $s->end_request if defined( $res ) || $s->{did_end};
  }# end unless()
  
  unless( $s->application->{__Application_Started} )
  {
    my $res = $s->handle_phase(
      $s->global_asa->can('Application_OnStart')
    );
    $s->application->{__Application_Started}++ unless $@;
    return $s->end_request if defined( $res ) || $s->{did_end};
  }# end unless()
  
  unless( $s->session->{__Started} )
  {
    my $res = $s->handle_phase(
      $s->global_asa->can('Session_OnStart')
    );
    $s->session->{__Started}++ unless $@;
    return $s->end_request if defined( $res ) || $s->{did_end};
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
  return $s->response->Status == 200 ? undef : $s->response->Status;
}# end handle_phase()


#==============================================================================
sub handle_error
{
  my $s = shift;
  warn $@;
  eval { $s->global_asa->can('Script_OnError')->( $@ ) };
  $s->response->Status( 500 );
}# end handle_error()


#==============================================================================
sub end_request
{
  my $s = shift;
  
  $s->handle_phase( $s->global_asa->can('Script_OnEnd') );
  
  $s->response->End;
  $s->session->save;
  $s->application->save;
  my $res = $s->response->Status == 200 ? 0 : $s->response->Status;
  
  return $res;
}# end end_request()


#==============================================================================
sub clone
{
  my $s = shift;
  
  return bless {%$s}, ref($s);
}# end clone()


#==============================================================================
sub config       { $_[0]->{config}                }
sub session      { $_[0]->{session}               }
sub server       { $_[0]->{server}                }
sub request      { $_[0]->{request}               }
sub response     { $_[0]->{response}              }
sub application  { $_[0]->{application}           }
sub stash        { $_[0]->{stash}                 }
sub global_asa   { $_[0]->{global_asa}            }
sub r            { $_[0]->{r}                     }
sub cgi          { $_[0]->{cgi}                   }
sub handler      { $_[0]->{handler}               }
sub connection   { $_[0]->{connection}            }
sub page         { $_[0]->{page}                  }

# Need to get this figured out:
sub headers_in   { shift->{headers_in}       }
sub send_headers
{
  my $s = shift;
  
  my $headers = $s->{headers_out};
  my $out = $s->{r}->headers_out;
  while( my ($k,$v) = each(%$headers) )
  {
    $out->{$k} = $v;
  }# end while()
  
  if( $s->{r}->can('send_headers') )
  {
    $s->{r}->headers_out->{$_} = $out->{$_} foreach keys(%$out);
    $s->{r}->send_headers;
  }
  else
  {
    $s->{r}->headers_out( $out );
  }# end if()
  $s->{_did_send_headers}++;
}# end send_headers()

sub headers_out  { shift->{headers_out} }
sub content_type { shift->{r}->content_type( @_ ) }
sub print
{
  my ($s, $str) = @_;
  $s->{_cache_buffer} .= $str;
  $s->{r}->print( $str );
}# end print()
sub rflush       { shift->{r}->rflush( @_ )       }
sub did_send_headers { shift->{_did_send_headers} }


#==============================================================================
sub resolve_request_handler
{
  my ($s, $uri) = @_;
  
  ($uri) = split /\?/, $uri;
  if( $uri =~ m/\.asp$/ )
  {
    my $handler = 'Apache2::ASP::ASPHandler';
    $s->load_class( $handler );
    return $handler;
  }
  elsif( $uri =~ m/^\/handlers\// )
  {
    (my $handler = $uri) =~ s/^\/handlers\///;
    $handler =~ s/[^a-z0-9_\.]/::/g;
warn "HANDLER: '$handler'";
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
    require $file;
#    $s->load_class( 'GlobalASA' );
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

