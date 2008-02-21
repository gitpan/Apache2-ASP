#!perl

use strict;
use warnings 'all';
use Test::More 'no_plan';
use Test::Exception;

use_ok('Apache2::ASP::GlobalConfig');

my $global;
lives_ok
  { $global = Apache2::ASP::GlobalConfig->new() }
  "Apache2::ASP::GlobalConfig->new() works the first time around.";

my $current = $global->domain_config( 'localhost' );
$current = $global->find_current_config();


foreach my $config ( $global->web_applications )
{
  # Go through each element, ensuring that a failure occurs whenever something 
  # is improperly configured:
  {
    my $con = bless { }, ref($config);
    throws_ok
      { $con->validate_config() }
      qr/web_application configuration is not defined/;
  }
  
  {
    local $config->{application_name} = undef;
    throws_ok
      { $config->validate_config() }
      qr/web_application\.application_name is not defined/;
  }
  
  # application_root:
  {
    local $config->{application_root} = undef;
    throws_ok
      { $config->validate_config() }
      qr/web_application\.application_root is not defined/;
    
#    local $config->{application_root} = '/path/just/doesnt/exist982134';
#    throws_ok
#      { $config->validate_config() }
#      qr/web_application\.application_root '.*?' does not exist/;
    
#    local $config->{application_root} = '/root';
#    throws_ok
#      { $config->validate_config() }
#      qr/web_application\.application_root '.*?' exists but is not readable/;
  }
  
  # page_cache_root:
  {
    local $config->{page_cache_root} = undef;
    throws_ok
      { $config->validate_config() }
      qr/web_application\.page_cache_root is not defined/;
    
#    local $config->{page_cache_root} = '/path/just/doesnt/exist982134';
#    throws_ok
#      { $config->validate_config() }
#      qr/web_application\.page_cache_root '.*?' does not exist/;
    
#    local $config->{page_cache_root} = '/root';
#    throws_ok
#      { $config->validate_config() }
#      qr/web_application\.page_cache_root '.*?' exists but is not readable/;
    
#    local $config->{page_cache_root} = '/var/log';
#    throws_ok
#      { $config->validate_config() }
#      qr/web_application\.page_cache_root '.*?' exists but is not writable/;
  }
  
  # www_root:
  {
    local $config->{www_root} = undef;
    throws_ok
      { $config->validate_config() }
      qr/web_application\.www_root is not defined/;
    
#    local $config->{www_root} = '/path/just/doesnt/exist982134';
#    throws_ok
#      { $config->validate_config() }
#      qr/web_application\.www_root '.*?' does not exist/;
    
#    local $config->{www_root} = '/root';
#    throws_ok
#      { $config->validate_config() }
#      qr/web_application\.www_root '.*?' exists but is not readable/;
  }
  
  # handler_root:
  {
    local $config->{handler_root} = undef;
    throws_ok
      { $config->validate_config() }
      qr/web_application\.handler_root is not defined/;
    
#    local $config->{handler_root} = '/path/just/doesnt/exist982134';
#    throws_ok
#      { $config->validate_config() }
#      qr/web_application\.handler_root '.*?' does not exist/;
    
#    local $config->{handler_root} = '/root';
#    throws_ok
#      { $config->validate_config() }
#      qr/web_application\.handler_root '.*?' exists but is not readable/;
  }
  
  # media_manager_upload_root:
  {
    local $config->{media_manager_upload_root} = undef;
    throws_ok
      { $config->validate_config() }
      qr/web_application\.media_manager_upload_root is not defined/;
    
#    local $config->{media_manager_upload_root} = '/path/just/doesnt/exist982134';
#    throws_ok
#      { $config->validate_config() }
#      qr/web_application\.media_manager_upload_root '.*?' does not exist/;
    
#    local $config->{media_manager_upload_root} = '/root';
#    throws_ok
#      { $config->validate_config() }
#      qr/web_application\.media_manager_upload_root '.*?' exists but is not readable/;
    
#    local $config->{media_manager_upload_root} = '/var/log';
#    throws_ok
#      { $config->validate_config() }
#      qr/web_application\.media_manager_upload_root '.*?' exists but is not writable/;
  }
  
  # web_application.session_state:
  {
    my $st = bless { %{ $config->{session_state} } }, ref($config->{session_state});
    local $config->{session_state} = undef;
    throws_ok
      { $config->validate_config() }
      qr/web_application\.session_state is not defined/;
      
    local $config->{session_state} = { };
    throws_ok
      { $config->validate_config() }
      qr/web_application\.session_state is a hash but has no keys/;
    
    local $config->{session_state} = $st;
    local $config->{session_state}->{manager} = undef;
    throws_ok
      { $config->validate_config() }
      qr/^web_application\.session_state.manager is not defined/;
      
    local $config->{session_state}->{manager} = 'UnknownClass';
    throws_ok
      { $config->validate_config() }
      qr/^web_application\.session_state.manager 'UnknownClass' cannot be loaded:/;
  }
  
  # web_application.application_state:
  {
    my $as = bless { %{ $config->{application_state} } }, ref($config->{application_state});
    local $config->{application_state} = undef;
    throws_ok
      { $config->validate_config() }
      qr/web_application\.application_state is not defined/;
      
    local $config->{application_state} = { };
    throws_ok
      { $config->validate_config() }
      qr/web_application\.application_state is a hash but has no keys/;
    
    local $config->{application_state} = $as;
    local $config->{application_state}->{manager} = undef;
    throws_ok
      { $config->validate_config() }
      qr/^web_application\.application_state.manager is not defined/;
    
    local $config->{application_state}->{manager} = 'UnknownClass';
    throws_ok
      { $config->validate_config() }
      qr/^web_application\.application_state.manager 'UnknownClass' cannot be loaded:/;
  }
  
  
  {
    # username parsed as a hashref, then as undef:
    {
      local $config->{application_state}->{username} = { };
      lives_ok
        { $config->validate_config() };
      local $config->{application_state}->{username} = undef;
      lives_ok
        { $config->validate_config() };
    }
    
    # password parsed as a hashref, then as undef:
    {
      local $config->{application_state}->{password} = { };
      lives_ok
        { $config->validate_config() };
      local $config->{application_state}->{password} = undef;
      lives_ok
        { $config->validate_config() };
    }
  }

}# end foreach()



__END__

# Try finding the config file under varying circumstances:
{
  delete local $ENV{APACHE2_ASP_APPLICATION_ROOT};
  ok( -f $config->_find_config_file(), '_find_config_file() works with no \$ENV{APACHE2_ASP_APPLICATION_ROOT}' );
  
  local $ENV{APACHE2_ASP_APPLICATION_ROOT} = '/invalid/path/to/application';
  ok( -f $config->_find_config_file(), '_find_config_file() works with invalid \$ENV{APACHE2_ASP_APPLICATION_ROOT}' );
  
  local $ENV{APACHE2_ASP_APPLICATION_ROOT} = $config->application_root;
  ok( -f $config->_find_config_file(), '_find_config_file() works with valid \$ENV{APACHE2_ASP_APPLICATION_ROOT}' );
  
  chdir("./t");
  local $ENV{APACHE2_ASP_APPLICATION_ROOT} = $config->application_root;
  ok( -f $config->_find_config_file(), '_find_config_file() works with valid \$ENV{APACHE2_ASP_APPLICATION_ROOT}' );
  chdir("../");
  
  rename( $config->application_root . '/conf/apache2-asp-config.xml', $config->application_root . '/conf/apache2-asp-config.xml.test' );
  eval {
    throws_ok
      { $config->_find_config_file() }
      qr/Cannot find configuration file anywhere\!/,
      '_find_config_file() fails when config file cannot be found';
  };
  rename( $config->application_root . '/conf/apache2-asp-config.xml.test', $config->application_root . '/conf/apache2-asp-config.xml' );
}

# Cover _load_config()
{
  my $config_filename = $config->application_root . '/conf/apache2-asp-config.xml';
  rename( $config_filename, "$config_filename.test" )
    or die "Cannot rename '$config_filename' to '$config_filename.test': $!";
  
  # Test for failure from invalid XML:
  open my $ofh, '>', $config_filename
    or die "Cannot open '$config_filename' for writing: $!";
  print $ofh <<EOF;
<blah bad xml sdlkfj sdflkj sdf><?.a>
EOF
  close($ofh);
  eval {
    dies_ok
      { $config->_load_config() }
      'Malformed XML in config causes error';
  };
  
  # Make sure that session_state and application_state are set to anonymous
  # hashrefs when they are not found within the XML itself:
  open $ofh, '>', $config_filename
    or die "Cannot open '$config_filename' for writing: $!";
  print $ofh <<EOF;
<this><is /><ok /></this>
EOF
  close($ofh);
  ok( $config->_load_config() );
  
  # Move the original config file back:
  rename( "$config_filename.test", $config_filename )
    or die "Cannot rename '$config_filename.test' to '$config_filename': $!";
}

# Try to call an invalid method on the $config object:
throws_ok
  { $config->parameter_doesnt_exist }
  qr/Invalid config property 'parameter_doesnt_exist'/,
  '$config fails when an invalid paramter is requested';










