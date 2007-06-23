
package Apache2::ASP::GlobalConfig;

use strict;
use warnings 'all';
use Apache2::ASP::Config;
use XML::Simple ();
use Sys::Hostname ();
use Cwd 'cwd';

my $CONFIG_PATH = 'conf/apache2-asp-config.xml';


#==============================================================================
sub new
{
  my $class = shift;
  
  my $global = $class->_load_config();

  # Convert the data structures into actual Config objects:
  foreach( @{ $global->{web_application} } )
  {
    $_ = Apache2::ASP::Config->new( $_ );
  }# end foreach()
  
  # Done!
  return bless $global, $class;
}# end new()


#==============================================================================
sub find_current_config
{
  my $s = shift;
  
  my $domain = $ENV{HTTP_HOST} || Sys::Hostname::hostname();
  
  return $s->domain_config( $domain );
}# end find_current_config()


#==============================================================================
sub domain_config
{
  my ($s, $domain) = @_;
  
  my ($config) = grep {
    $domain =~ m/$_->{domain_re}/
  } $s->web_applications;
  
  return $config;
}# end domain_config()


#==============================================================================
sub web_applications
{
  my $s = shift;
  
  @{ $s->{web_application} };
}# end web_applications()


#==============================================================================
sub _find_config_file
{
  my $testing_mode = 0;
  no warnings 'uninitialized';
  $ENV{APACHE2_ASP_APPLICATION_ROOT} =~ s/\/+$//;
  if( ! $ENV{APACHE2_ASP_APPLICATION_ROOT} )
  {
    $ENV{APACHE2_ASP_APPLICATION_ROOT} = '.';
    $testing_mode = 1;
  }# end if()

  # First load the configuration:
  my $file = "$ENV{APACHE2_ASP_APPLICATION_ROOT}/$CONFIG_PATH";
  if( ! -f $file )
  {
    $ENV{APACHE2_ASP_APPLICATION_ROOT} = './t';
    $file = "$ENV{APACHE2_ASP_APPLICATION_ROOT}/$CONFIG_PATH";
    if( ! -f $file )
    {
      $file = cwd() . $CONFIG_PATH;
      return $file if -f $file;
      $file = cwd() . "/t/$CONFIG_PATH";
      die "Cannot find configuration file anywhere!  It should be found at \$ENV{APACHE2_ASP_APPLICATION_ROOT}/$CONFIG_PATH";
    }# end if()
  }# end if()
  return $file;
}# end _find_config_file()


#==============================================================================
sub _load_config
{
  my ($s) = @_;
  
  my $file = $s->_find_config_file();
  
  # Now parse the XML:
  my $xml = eval {
    XML::Simple::XMLin( $file, ForceArray => [qw/ web_application /] )
  } or die "Cannot load $file: $@";
  
  # Setup defaults and make sure that (array|hash)refs exist where they are expected to:
  # Default Session & Application state settings:
  foreach( @{ $xml->{web_application} } )
  {
    $_->{session_state} ||= { };
    $_->{application_state} ||= { };
  }# end foreach()
  
  # Done parsing:
  return $xml;
}# end _load_config()


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

sub DESTROY { }

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::GlobalConfig - Config manager for Apache2::ASP web applications

=head1 SYNOPSIS

  my $global = Apache2::ASP::GlobalConfig->new();
  
  # Find config based on $ENV{HTTP_HOST} or `domain`:
  my $current = $global->find_current_config();
  
  # Find config for a specific domain:
  my $domain_config = $global->domain_config( 'whatever.com' );
  
  # Get a list of all web application configs:
  my @configs = $global->web_applications;

=head1 DESCRIPTION

C<Apache2::ASP::GlobalConfig> attempts to keep all of your web applications' configuration data in one place:

B<Your /conf/apache2-asp-config.xml file.>

It should look like this:

  <?xml version="1.0" ?>
  <config>
    <web_application>
      <domain_re>.*</domain_re>
      <do_reload_on_script_change>1</do_reload_on_script_change>
      <application_name>DefaultApp</application_name>
      <application_root>@ServerRoot@</application_root>
      <handler_root>@ServerRoot@/handlers</handler_root>
      <media_manager_upload_root>@ServerRoot@/MEDIA</media_manager_upload_root>
      <www_root>@ServerRoot@/htdocs</www_root>
      <page_cache_root>@ServerRoot@/PAGE_CACHE</page_cache_root>
      <application_state>
        <manager>Apache2::ASP::ApplicationStateManager::MySQL</manager>
        <dsn>DBI:mysql:dstack_dev:localhost</dsn>
        <password>j@p@n</password>
        <username>root</username>
      </application_state>
      <session_state>
        <manager>Apache2::ASP::SessionStateManager::SQLite</manager>
        <cookie_domain>apache2-asp.no-ip.org</cookie_domain>
        <cookie_name>session-id</cookie_name>
        <dsn>DBI:mysql:dstack_dev:localhost</dsn>
        <password>j@p@n</password>
        <username>root</username>
        <session_timeout>30</session_timeout>
      </session_state>
    </web_application>
  </config>

If it doesn't look like that, an exception will be thrown.

Those little C<@ServerRoot@> tags are replaced with the value of C<$ENV{APACHE2_ASP_APPLICATION_ROOT}>
when the XML file is loaded up and parsed.

=head1 METHODS

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
