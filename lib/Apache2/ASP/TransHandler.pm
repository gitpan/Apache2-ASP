
package Apache2::ASP::TransHandler;

use strict;
use APR::Table ();
use Apache2::RequestRec ();
use Apache2::RequestUtil ();
use Apache2::SubRequest ();
use Apache2::Const -compile => ':common';
use Apache2::ServerRec ();

use Apache2::ASP::GlobalConfig;

our %configs = ();

sub handler : method
{
  my ($class, $r) = @_;
  
  $class->init_config( $r );
  
  # Fixup the request URI:
  my $filename = $r->filename;

  if( -d $filename )
  {
    # See if there is an index.asp here:
    if( -f $filename . "index.asp" )
    {
      $r->filename( $filename . "index.asp" );
      $r->uri( $r->uri . "/index.asp" );
      return -1;
    }
    else
    {
      # We don't do directory indexes:
      return 403;
    }# end if()
  }# end if()
  
  return -1;
}# end handler()


sub init_config
{
  my ($s, $r) = @_;
  
	my $domain = $r->hostname || $r->server->server_hostname;
	if( $configs{$domain} )
	{
		$ENV{APACHE2_ASP_GLOBAL_CONFIG} = $configs{$domain};
	}
	else
	{
		$ENV{APACHE2_ASP_GLOBAL_CONFIG} = $configs{$domain} = Apache2::ASP::GlobalConfig->new();
	  warn "Apache2::ASP::GlobalConfig($domain) has been loaded into \$ENV{APACHE2_ASP_GLOBALCONFIG}\n";
	}# end if()
	
	$ENV{APACHE2_ASP_CONFIG} = $ENV{APACHE2_ASP_GLOBAL_CONFIG}->find_current_config( $r );
}# end init_config()

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::TransHandler - URL Translations for Apache2::ASP web applications

=head1 SYNOPSIS

  # In your httpd.conf:
  PerlModule        Apache2::ASP::TransHandler
  PerlTransHandler  Apache2::ASP::TransHandler

=head1 DESCRIPTION

Simply converts requests for directories into requests for an C<index.asp> in that directory.

Returns C<403> if no C<index.asp> is found.

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
