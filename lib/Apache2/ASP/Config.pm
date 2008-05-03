
package Apache2::ASP::Config;

use strict;
use warnings 'all';
use base 'Apache2::ASP::Config::Node';


#==========================================================================
sub new
{
	my ($class, $data) = @_;
	
	my $s;
	if( $data )
	{
		$s = bless $data, $class;
	}
	else
	{
		require Apache2::ASP::GlobalConfig;
		$s = bless Apache2::ASP::GlobalConfig->new()->find_current_config, $class;
	}# end if()
	
	$s->{session_state} ||= { };
	$s->{application_state} ||= { };
	$s->{request_filters}->{filter} ||= [ ];
	$s->{__path} = 'web_application';
	$s->init_keys();
	
	$s->initialize_config;
	
	return $s;
}# end new()


#==========================================================================
sub request_filters
{
	@{ $_[0]->{request_filters}->{filter} };
}# end request_filters()


#==============================================================================
sub initialize_config
{
  my ($s) = @_;
	return if $s->{__initialized}++;

  $s->_fixup_path( 'application_root' );
  $s->_fixup_path( 'page_cache_root' );
  push @INC, $s->page_cache_root
    unless grep { $_ eq $s->page_cache_root } @INC;
  $s->_fixup_path( 'www_root' );
  $s->_fixup_path( 'handler_root' );
  push @INC, $s->handler_root
    unless grep { $_ eq $s->handler_root } @INC;
  $s->_fixup_path( 'media_manager_upload_root' );
	
  # Initialize other settings:
	$s->_fixup_path2( 'lib' );
	push @INC, $s->settings->lib;
	{
		(my $file = $s->session_state->manager . '.pm') =~ s/::/\//g;
		eval { require $file } unless $INC{$file};
		die "web_application.session_state.manager '@{[ $s->session_state->manager ]}' cannot be loaded: $@"
			if $@;
	}
	{
		(my $file = $s->application_state->manager . '.pm') =~ s/::/\//g;
		eval { require $file } unless $INC{$file};
		die "web_application.application_state.manager '@{[ $s->application_state->manager ]}' cannot be loaded: $@"
			if $@;
	}
	{
		(my $file = $s->settings->orm_base_class . '.pm') =~ s/::/\//g;
		eval { require $file } unless $INC{$file};
		die "web_application.settings.orm_base_class '@{[ $s->settings->orm_base_class ]}' cannot be loaded: $@"
			if $@;
	}
}# end initialize_config()


#==============================================================================
# Sanity checks to make sure the configuration will work:
#sub validate_config
#{
#  my ($s) = @_;
#	return if $s->{__validated}++;
#  
#  die "web_application configuration is not defined"
#    unless keys(%$s);
#  
#  die "web_application.application_name is not defined"
#    unless defined($s->application_name);
#  
#  die "web_application.application_root is not defined"
#    unless defined($s->{application_root});
#  
##  $s->_fixup_path( 'application_root' );
#  
#  die "web_application.domain_re is not defined"
#    unless defined($s->{domain_re});
#  
#  eval { 'whatever' =~ m/$s->{domain_re}/ };
#  die "web_application.domain_re has errors: $@"
#    if $@;
#  
#  die "web_application.application_root '@{[ $s->application_root ]}' does not exist"
#    unless -d $s->application_root;
#  
#  die "web_application.application_root '@{[ $s->application_root ]}' exists but is not readable"
#    unless -r $s->application_root;
#    
#  die "web_application.page_cache_root is not defined"
#    unless defined($s->{page_cache_root});
#  
##  $s->_fixup_path( 'page_cache_root' );
#
#  mkdir $s->page_cache_root unless -d $s->page_cache_root;
#  die "web_application.page_cache_root '@{[ $s->page_cache_root ]}' does not exist"
#    unless -d $s->page_cache_root;
#  mkdir $s->page_cache_root . '/' . $s->application_name
#    unless -d $s->page_cache_root . '/' . $s->application_name;
#  die "Cannot find or create the page cache for this application at '" . $s->page_cache_root . '/' . $s->application_name . "'"
#    unless -d $s->page_cache_root . '/' . $s->application_name;
#  
#  die "web_application.page_cache_root '@{[ $s->page_cache_root ]}' exists but is not readable"
#    unless -r $s->page_cache_root;
#  
#  die "web_application.page_cache_root '@{[ $s->page_cache_root ]}' exists but is not writable"
#    unless -w $s->page_cache_root;
#  
##  push @INC, $s->page_cache_root
##    unless grep { $_ eq $s->page_cache_root } @INC;
#  
#  die "web_application.www_root is not defined"
#    unless defined($s->{www_root});
#    
##  $s->_fixup_path( 'www_root' );
#  
#  die "web_application.www_root '@{[ $s->www_root ]}' does not exist"
#    unless -d $s->www_root;
#  
#  die "web_application.www_root '@{[ $s->www_root ]}' exists but is not readable"
#    unless -r $s->www_root;
#  
#  die "web_application.handler_root is not defined"
#    unless defined($s->{handler_root});
#  
##  $s->_fixup_path( 'handler_root' );
#  
#  die "web_application.handler_root '@{[ $s->handler_root ]}' does not exist"
#    unless -d $s->handler_root;
#  
##  push @INC, $s->handler_root
##    unless grep { $_ eq $s->handler_root } @INC;
#  
#  die "web_application.handler_root '@{[ $s->handler_root ]}' exists but is not readable"
#    unless -r $s->handler_root;
#  
#  die "web_application.media_manager_upload_root is not defined"
#    unless defined($s->{media_manager_upload_root});
#  
##  $s->_fixup_path( 'media_manager_upload_root' );
#  
#  die "web_application.media_manager_upload_root '@{[ $s->media_manager_upload_root ]}' does not exist"
#    unless -d $s->media_manager_upload_root;
#  
#  die "web_application.media_manager_upload_root '@{[ $s->media_manager_upload_root ]}' exists but is not readable"
#    unless -r $s->media_manager_upload_root;
#  
#  die "web_application.media_manager_upload_root '@{[ $s->media_manager_upload_root ]}' exists but is not writable"
#    unless -w $s->media_manager_upload_root;
#  
#  die "web_application.session_state is not defined"
#    unless defined($s->{session_state});
#  
#  die "web_application.session_state is a hash but has no keys"
#    unless keys( %{ $s->{session_state} } );
#  
#  die "web_application.session_state.manager is not defined"
#    unless defined($s->{session_state}->{manager});
#  
#  die "web_application.application_state is not defined"
#    unless defined($s->{application_state});
#  
#  die "web_application.application_state is a hash but has no keys"
#    unless keys( %{ $s->{application_state} } );
#  
#  die "web_application.application_state.manager is not defined"
#    unless defined($s->{application_state}->{manager});
#  
#}# end validate_config()


#==============================================================================
# Do any preprocessing on a path-based value:
sub _fixup_path
{
  my ($s, $field) = @_;
  
  my $original = $s->{"$field\_original"} ? $s->{"$field\_original"} : $s->{$field};
  my $fixed = $original;
  my $root = $ENV{APACHE2_ASP_APPLICATION_ROOT};
  $fixed =~ s/\@ServerRoot\@/$root/g;
  $s->{"$field\_original"} = $original;
  $s->{"$field\_expanded"} = $fixed;
  
  $s->{$field} = $fixed;
}# end _fixup_path()


#==============================================================================
# Do any preprocessing on a path-based value:
sub _fixup_path2
{
  my ($s, $field) = @_;
  
  my $original = $s->{settings}->{"$field\_original"} ? $s->{settings}->{"$field\_original"} : $s->{settings}->{$field};
  my $fixed = $original;
  my $root = $ENV{APACHE2_ASP_APPLICATION_ROOT};
  $fixed =~ s/\@ServerRoot\@/$root/g;
  $s->{settings}->{"$field\_original"} = $original;
  $s->{settings}->{"$field\_expanded"} = $fixed;
  
  $s->{settings}->{$field} = $fixed;
}# end _fixup_path2()

1;# return true:
