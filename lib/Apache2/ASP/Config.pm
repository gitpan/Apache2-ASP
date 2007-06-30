
package Apache2::ASP::Config;

use strict;
use warnings 'all';


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
  if( $s->{settings} )
  {
    bless $s->{settings}, $class;
    $s->settings->_fixup_path( 'lib' );
    push @INC, $s->settings->lib;
  }# end if()
  
  return $s;
}# end new()


#==============================================================================
# Sanity checks to make sure the configuration will work:
sub validate_config
{
  my $s = shift;
  
  die "web_application configuration is not defined"
    unless keys(%$s);
  
  die "web_application.application_name is not defined"
    unless defined($s->{application_name});
  
  die "web_application.application_root is not defined"
    unless defined($s->{application_root});
  
  $s->_fixup_path( 'application_root' );
  
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
  
  $s->_fixup_path( 'page_cache_root' );

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
  
  push @INC, $s->page_cache_root;
  
  die "web_application.www_root is not defined"
    unless defined($s->{www_root});
    
  $s->_fixup_path( 'www_root' );
  
  die "web_application.www_root '@{[ $s->www_root ]}' does not exist"
    unless -d $s->www_root;
  
  die "web_application.www_root '@{[ $s->www_root ]}' exists but is not readable"
    unless -r $s->www_root;
  
  die "web_application.handler_root is not defined"
    unless defined($s->{handler_root});
  
  $s->_fixup_path( 'handler_root' );
  
  die "web_application.handler_root '@{[ $s->handler_root ]}' does not exist"
    unless -d $s->handler_root;
  
  push @INC, $s->handler_root;
  
  die "web_application.handler_root '@{[ $s->handler_root ]}' exists but is not readable"
    unless -r $s->handler_root;
  
  die "web_application.media_manager_upload_root is not defined"
    unless defined($s->{media_manager_upload_root});
  
  $s->_fixup_path( 'media_manager_upload_root' );
  
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
  
  $s->{session_state}->{username} = undef
    if ref($s->{session_state}->{username});
  $s->{session_state}->{password} = undef
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
  
  $s->{application_state}->{username} = undef
    if ref($s->{application_state}->{username});
  $s->{application_state}->{password} = undef
    if ref($s->{application_state}->{password});
  
}# end validate_config()


#==============================================================================
# Do any preprocessing on a path-based value:
sub _fixup_path
{
  my ($s, $field) = @_;
  
  my $fixed = $s->{$field};
  my $original = $s->{"$field\_original"} ? $s->{"$field\_original"} : $s->{$field};
  $fixed =~ s/\@ServerRoot\@/$ENV{APACHE2_ASP_APPLICATION_ROOT}/g;
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
  
  print $config->www_root;                        # /usr/local/dstack/htdocs
  
  print $config->application_name;                # DefaultApp
  
  print $config->handler_root;                    # /usr/local/dstack/handlers
  
  print $config->page_cache_root;                 # /usr/local/dstack/PAGE_CACHE
  
  print $config->media_manager_upload_root;       # /usr/local/dstack/MEDIA
  
  print $config->application_state->manager;      # Apache2::ASP::ApplicationStateManager::SQLite
  
  print $config->application_state->dsn;          # DBI:SQLite:dbname=/tmp/apache2_asp_state
  
  print $config->session_state->manager;          # Apache2::ASP::SessionStateManager::SQLite
  
  print $config->session_state->cookie_domain;    # .yoursite.com
  
  print $config->session_state->cookie_name;      # session-id
  
  print $config->session_state->dsn;              # DBI:SQLite:dbname=/tmp/apache2_asp_state
  
  print $config->session_state->session_timeout;  # 30 (means 30 minutes)

=head1 DESCRIPTION

Each web application gets its own configuration.  For more information about the config xml format,
see L<Apache2::ASP::GlobalConfig>.

=head1 METHODS

=head2 new( )

Returns a new C<Apache2::ASP::Config> object.

=head2 validate_config( )

Used for testing, but it could (possibly) be useful some other way.  Validates the config.  Dies if the config contains errors.

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
