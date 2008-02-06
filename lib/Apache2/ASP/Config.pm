
package Apache2::ASP::Config;

use strict;
use warnings 'all';

use Apache2::ASP::Config::Node;

use Apache2::Directive ();
use Sys::Hostname ();
our %AppPath = ();


#==============================================================================
sub new
{
  my ($class, $data) = @_;
  my $s;
  
  if( $data )
  {
    $s = bless $data, $class;
    $s->validate_config();
  }
  else
  {
    require Apache2::ASP::GlobalConfig;
    my $global = Apache2::ASP::GlobalConfig->new();
    $s = $global->find_current_config();
  }# end if()
  bless $s->{session_state}, $class;
  bless $s->{application_state}, $class;
  
  $s->_init_settings();
  $s->_init_request_filters();
  
  return $s;
}# end new()


#==============================================================================
# Sanity checks to make sure the configuration will work:
sub validate_config
{
  my ($s, $domain) = @_;
  
  die "web_application configuration is not defined"
    unless keys(%$s);
  
  die "web_application.application_name is not defined"
    unless defined($s->{application_name});
  
  die "web_application.application_root is not defined"
    unless defined($s->{application_root});
  
  $s->_fixup_path( 'application_root', $domain );
  
  die "web_application.domain_re is not defined"
    unless defined($s->{domain_re});
  
  eval { 'whatever' =~ m/$s->{domain_re}/ };
  die "web_application.domain_re has errors: $@"
    if $@;
  
  die "web_application.application_root '@{[ $s->application_root ]}' does not exist"
    unless -d $s->application_root;
  
  die "web_application.application_root '@{[ $s->application_root ]}' exists but is not readable"
    unless -r $s->application_root;
    
  die "web_application.page_cache_root is not defined"
    unless defined($s->{page_cache_root});
  
  $s->_fixup_path( 'page_cache_root', $domain );

# Maybe enable these validations later, once we have tests for them:
#  mkdir $s->page_cache_root unless -d $s->page_cache_root;
  die "web_application.page_cache_root '@{[ $s->page_cache_root ]}' does not exist"
    unless -d $s->page_cache_root;
#  mkdir $s->page_cache_root . '/' . $s->application_name
#    unless -d $s->page_cache_root . '/' . $s->application_name;
#  die "Cannot find or create the page cache for this application at '" . $s->page_cache_root . '/' . $s->application_name . "'"
#    unless -d $s->page_cache_root . '/' . $s->application_name;
  
  die "web_application.page_cache_root '@{[ $s->page_cache_root ]}' exists but is not readable"
    unless -r $s->page_cache_root;
  
  die "web_application.page_cache_root '@{[ $s->page_cache_root ]}' exists but is not writable"
    unless -w $s->page_cache_root;
  
  push @INC, $s->page_cache_root
    unless grep { $_ eq $s->page_cache_root } @INC;
  
  die "web_application.www_root is not defined"
    unless defined($s->{www_root});
    
  $s->_fixup_path( 'www_root', $domain );
  
  die "web_application.www_root '@{[ $s->www_root ]}' does not exist"
    unless -d $s->www_root;
  
  die "web_application.www_root '@{[ $s->www_root ]}' exists but is not readable"
    unless -r $s->www_root;
  
  die "web_application.handler_root is not defined"
    unless defined($s->{handler_root});
  
  $s->_fixup_path( 'handler_root', $domain );
  
  die "web_application.handler_root '@{[ $s->handler_root ]}' does not exist"
    unless -d $s->handler_root;
  
  push @INC, $s->handler_root
    unless grep { $_ eq $s->handler_root } @INC;
  
  die "web_application.handler_root '@{[ $s->handler_root ]}' exists but is not readable"
    unless -r $s->handler_root;
  
  die "web_application.media_manager_upload_root is not defined"
    unless defined($s->{media_manager_upload_root});
  
  $s->_fixup_path( 'media_manager_upload_root', $domain );
  
  die "web_application.media_manager_upload_root '@{[ $s->media_manager_upload_root ]}' does not exist"
    unless -d $s->media_manager_upload_root;
  
  die "web_application.media_manager_upload_root '@{[ $s->media_manager_upload_root ]}' exists but is not readable"
    unless -r $s->media_manager_upload_root;
  
  die "web_application.media_manager_upload_root '@{[ $s->media_manager_upload_root ]}' exists but is not writable"
    unless -w $s->media_manager_upload_root;
  
  die "web_application.session_state is not defined"
    unless defined($s->{session_state});
  
  die "web_application.session_state is a hash but has no keys"
    unless keys( %{ $s->{session_state} } );
  
  die "web_application.session_state.manager is not defined"
    unless defined($s->{session_state}->{manager});
  
  if( ! eval { $s->{session_state}->{manager}->isa('UNIVERSAL') } )
  {
    my ($filename); ($filename = $s->{session_state}->{manager} ) =~ s/::/\//g;
    eval { require "$filename.pm" };
    die "web_application.session_state.manager '$s->{session_state}->{manager}' cannot be loaded: $@"
      if $@;
  }# end if()
  
  $s->{session_state}->{username} = ''
    if ref($s->{session_state}->{username});
  $s->{session_state}->{password} = ''
    if ref($s->{session_state}->{password});
  
  die "web_application.application_state is not defined"
    unless defined($s->{application_state});
  
  die "web_application.application_state is a hash but has no keys"
    unless keys( %{ $s->{application_state} } );
  
  die "web_application.application_state.manager is not defined"
    unless defined($s->{application_state}->{manager});
  
  if( ! eval { $s->{application_state}->{manager}->isa('UNIVERSAL') } )
  {
    my ($filename); ($filename = $s->{application_state}->{manager} ) =~ s/::/\//g;
    eval { require "$filename.pm" };
    die "web_application.application_state.manager '$s->{application_state}->{manager}' cannot be loaded: $@"
      if $@;
  }# end if()
  
  $s->{application_state}->{username} = ''
    if ref($s->{application_state}->{username});
  $s->{application_state}->{password} = ''
    if ref($s->{application_state}->{password});
  
  $s->_init_settings();
  $s->_init_request_filters();
}# end validate_config()


#==============================================================================
# Return an array of filter objects:
sub request_filters
{
  @{ $_[0]->{request_filters}->{filter} };
}# end request_filters()


#==============================================================================
sub _init_request_filters
{
  my $s = shift;
  
  $s->{request_filters} ||= { filter => [ ] };
  
  my @filters = @{ $s->{request_filters}->{filter} };
  foreach my $filter ( @filters )
  {
    $filter = Apache2::ASP::Config::Node->new( %$filter );
  }# end foreach()
}# end _init_request_filters()


#==============================================================================
sub _init_settings
{
  my $s = shift;
  
  if( $s->{settings} )
  {
    foreach my $key ( keys(%{ $s->{settings} }) )
    {
      if( ref($s->{settings}->{$key}) )
      {
        if( keys(%{ $s->{settings}->{$key} }) )
        {
          bless $s->{settings}->{$key}, ref($s);
        }
        else
        {
          $s->{settings}->{$key} = '';
        }# end if()
      }# end if()
    }# end foreach()
    
    bless $s->{settings}, ref($s);
    $s->settings->_fixup_path( 'lib', $ENV{HTTP_HOST} );
    push @INC, $s->settings->lib
      unless grep { $_ eq $s->settings->lib } @INC;
  }# end if()
}# end _init_settings()


#==============================================================================
sub _application_path
{
  my ($s, $domain) = @_;
  
  return $ENV{APACHE2_ASP_APPLICATION_ROOT};
  
  return $AppPath{ $domain }
    if $AppPath{ $domain };
  my ($tree) = eval { Apache2::Directive::conftree() };
  return $ENV{APACHE2_ASP_APPLICATION_ROOT} unless $tree;
  
  my @vhosts = $tree->lookup('VirtualHost');
  my $dir;
  if( @vhosts )
  {
    no warnings 'uninitialized';
    my ($host) = grep {
      $_->{ServerName} eq $domain
      ||
      $_->{ServerAlias} eq $domain
    } @vhosts;
    $dir = $host->{DocumentRoot};
  }
  else
  {
    $dir = $tree->lookup('DocumentRoot');
  }# end if()
  $dir =~ s/"//g;
  
  my @parts = split /\//, $dir;
  pop(@parts);
  return $AppPath{ $domain } = join '/', @parts;
}# end _application_path()


#==============================================================================
# Do any preprocessing on a path-based value:
sub _fixup_path
{
  my ($s, $field, $domain) = @_;
  
  my $original = $s->{"$field\_original"} ? $s->{"$field\_original"} : $s->{$field};
  my $fixed = $original;
  my $root = $s->_application_path( $domain ? $domain : $ENV{HTTP_HOST} ? $ENV{HTTP_HOST} : Sys::Hostname::hostname() );
  $fixed =~ s/\@ServerRoot\@/$root/g;
  $s->{"$field\_original"} = $original;
  $s->{"$field\_expanded"} = $fixed;
  
  $s->{$field} = $fixed;
}# end _fixup_path()


#==============================================================================
# Discourage the use of public hash notation - use $config->property_name instead:
sub AUTOLOAD
{
  my $s = shift;
  our $AUTOLOAD;
  my ($key) = $AUTOLOAD =~ m/::([^:]+)$/;
  if( exists($s->{ $key }) )
  {
    return $s->{ $key };
  }
  else
  {
    die "Invalid config property '$key'";
  }# end if()
}# end AUTOLOAD()


#==============================================================================
sub DESTROY { }


1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::Config - Configuration object for Apache2::ASP web applications.

=head1 READ THIS FIRST

B<NOTE:> This module requires the environment variable C<$ENV{APACHE2_ASP_APPLICATION_ROOT}> to be set 
to the path where your Apache2::ASP application lives.

For instance, say you keep your website at C</var/www> - you would set C<$ENV{APACHE2_ASP_APPLICATION_ROOT}> to 
C</var/www>.

If you keep your *.asp pages inside C</var/www/htdocs> - you would still set C<$ENV{APACHE2_ASP_APPLICATION_ROOT}>
to C</var/www>.

If you keep your *.asp pages inside C</usr/local/mywebsite/htdocs> - you would set C<$ENV{APACHE2_ASP_APPLICATION_ROOT}>
to C</usr/local/mywebsite>.

If C<$ENV{APACHE2_ASP_APPLICATION_ROOT}> is not set, C<Apache2::ASP::Config> will do its best to guess it for you.  Usually
it's pretty good at it, and you will never know the difference.  However, if this module keeps failing and can't find your
config file, it's most likely because C<$ENV{APACHE2_ASP_APPLICATION_ROOT}> was not properly set.

Clear?  Good.

=head1 SYNOPSIS

  use Apache2::ASP::Config;
  my $config = Apache2::ASP::Config->new();
  
  print $config->www_root;                        # /var/www/html
  
  print $config->application_name;                # DefaultApp
  
  print $config->handler_root;                    # /var/www/html/handlers
  
  print $config->page_cache_root;                 # /var/www/html/PAGE_CACHE
  
  print $config->media_manager_upload_root;       # /var/www/html/MEDIA
  
  print $config->application_state->manager;      # Apache2::ASP::ApplicationStateManager::SQLite
  
  print $config->application_state->dsn;          # DBI:SQLite:dbname=/tmp/apache2_asp_state
  
  print $config->application_state->username;     # "username"
  
  print $config->application_state->password;     # "password"
  
  print $config->session_state->manager;          # Apache2::ASP::SessionStateManager::SQLite
  
  print $config->session_state->cookie_domain;    # .yoursite.com
  
  print $config->session_state->cookie_name;      # session-id
  
  print $config->session_state->dsn;              # DBI:SQLite:dbname=/tmp/apache2_asp_state
  
  print $config->session_state->username;         # "username"
  
  print $config->session_state->password;         # "password"
  
  print $config->session_state->session_timeout;  # 30 (means 30 minutes)
  
  print $config->settings->lib;                   # /usr/local
  
  print $config->settings->dsn;                   # DBI:mysql:dbname:hostname
  
  print $config->settings->username;              # "username"
  
  print $config->settings->password;              # "password"

=head1 DESCRIPTION

Each web application gets its own configuration.  For more information about the config xml format,
see L<Apache2::ASP::GlobalConfig>.

For information on setting up the configuration, please refer to L<Apache2::ASP::Manual::Intro> 
and L<Apache2::ASP::Manual::ConfigXML>.

=head1 PUBLIC METHODS

=head2 new( )

Returns a new C<Apache2::ASP::Config> object.

=head2 validate_config( )

Used for testing, but it could (possibly) be useful some other way.  Validates the config.  Dies if the config contains errors.

=head1 PUBLIC PROPERTIES

=head2 $config->www_root

Returns 

=head2 $config->application_name

See synopsis.

=head2 $config->handler_root

See synopsis.

=head2 $config->page_cache_root

See synopsis.

=head2 $config->media_manager_upload_root

See synopsis.

=head2 $config->application_state->manager

See synopsis.

=head2 $config->application_state->dsn

See synopsis.

=head2 $config->application_state->username

See synopsis.

=head2 $config->application_state->password

See synopsis.

=head2 $config->session_state->manager

See synopsis.

=head2 $config->session_state->cookie_domain

See synopsis.

=head2 $config->session_state->cookie_name

See synopsis.

=head2 $config->session_state->dsn

See synopsis.

=head2 $config->session_state->username

See synopsis.

=head2 $config->session_state->password

See synopsis.

=head2 $config->settings->lib

The path to your Application-specific Perl modules, B<not> your Handlers.

Generally these are L<Class::DBI> or L<DBIx::Class> modules (or whatever you prefer to use).

=head2 $config->settings->dsn

The connectionstring your application uses.

=head2 $config->settings->username

The username for your application's connectionstring.

=head2 $config->settings->password

The password for your application's connectionstring.

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
