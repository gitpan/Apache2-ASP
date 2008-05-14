
package Apache2::ASP::GlobalConfig;

use strict;
use warnings 'all';
use XML::Simple ();
use Apache2::ASP::Config;
use Sys::Hostname ();
use Cwd 'cwd';

my $CONFIG_FILE = 'apache2-asp-config.xml';


#==========================================================================
sub new
{
	my ($class, %args) = @_;
	
	my $config_path = $class->find_config_path or die "Cannot find config anywhere!";
	
	my $xml = eval {
		XML::Simple::XMLin( $config_path,
			ForceArray => [qw/ web_application filter /],
			SuppressEmpty => '',
		);
	} or die "Cannot load config file '$config_path': $@";
  foreach( @{ $xml->{web_application} } )
  {
		$_ = Apache2::ASP::Config->new( $_ );
  }# end foreach()
	
	return bless $xml, $class;
}# end new()


#==========================================================================
# Public Properties:
sub web_applications { @{ $_[0]->{web_application} } }


#==========================================================================
sub find_current_config
{
  my ($s, $r) = @_;
	
	my $domain;
	if( $r )
	{
		$domain = $r->hostname || $r->server->server_hostname;
	}
	else
	{
		$domain = $ENV{HTTP_HOST} || Sys::Hostname::hostname() || 'localhost';
	}# end if()
  
  my $config = $s->domain_config( $domain );
  unless( $config )
  {
    ($config) = $s->web_applications;
  }# end unless()
	
  return Apache2::ASP::Config->new( $config );
}# end find_current_config()


#==========================================================================
sub domain_config
{
  my ($s, $domain) = @_;
  
  my ($config) = grep {
    $domain =~ m/$_->{domain_re}/
  } $s->web_applications;
  
  return $config;
}# end domain_config()


#==========================================================================
sub find_config_path
{
	my ($s, $r) = @_;
	
	if( $r && $s->test_config_path( $r->dir_config("APACHE2_ASP_CONFIG_PATH") ) )
	{
		return $r->dir_config("APACHE2_ASP_CONFIG_PATH");
	}
	else
	{
		$ENV{APACHE2_ASP_APPLICATION_ROOT} ||= cwd();
		if( -f "$ENV{APACHE2_ASP_APPLICATION_ROOT}/conf/apache2-asp-config.xml" )
		{
			return "$ENV{APACHE2_ASP_APPLICATION_ROOT}/conf/apache2-asp-config.xml";
		}
		elsif( -f "$ENV{APACHE2_ASP_APPLICATION_ROOT}/t/conf/apache2-asp-config.xml" )
		{
			$ENV{APACHE2_ASP_APPLICATION_ROOT} .= "/t";
			return "$ENV{APACHE2_ASP_APPLICATION_ROOT}/conf/apache2-asp-config.xml";
		}
		else
		{
			my (@parts) = split /\//, $ENV{APACHE2_ASP_APPLICATION_ROOT};
			pop(@parts);
			my $newpath = join '/', @parts;
			if( -f "$newpath/conf/apache2-asp-config.xml" )
			{
				$ENV{APACHE2_ASP_APPLICATION_ROOT} = $newpath;
				return "$ENV{APACHE2_ASP_APPLICATION_ROOT}/conf/apache2-asp-config.xml";
			}# end if()
		}# end if()
		
		die "Cannot find config file anywhere!";
	}# end if()
}# end find_config_path()


#==========================================================================
sub test_config_path
{
	my ($s, $path) = @_;
	
	return -f $path;
}# end test_config_path()




1;# return true:

__END__

=pod

=head1 NAME

=head1 SYNOPSIS

	use Apache2::ASP::ConfigLoader;
	
	my $loader = Apache2::ASP::ConfigLoader->new(
		config_path => '/path/to/config.xml'
	);

=head1 DESCRIPTION

=head1 PUBLIC METHODS

=cut
