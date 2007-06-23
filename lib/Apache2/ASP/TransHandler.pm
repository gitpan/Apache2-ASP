
package Apache2::ASP::TransHandler;

use strict;
use APR::Table ();
use Apache2::RequestRec ();
use Apache2::Const -compile => ':common';

sub handler : method
{
  my ($class, $r) = @_;
  
  # Get our config:
  $ENV{APACHE2_ASP_CONFIG} = $ENV{APACHE2_ASP_GLOBALCONFIG}->find_current_config();
  
  # Fixup the request URI:
  my $filename = $r->filename;
  if( -d $filename )
  {
    # See if there is an index.asp here:
    if( -f $filename . "index.asp" )
    {
      $r->filename( $filename . "index.asp" );
      return $class->handler( $r );
    }
    else
    {
      # We don't do directory indexes:
      return 403;
    }# end if()
  }
  else
  {
    # Fixup /media/* URL requests:
    return Apache2::Const::DECLINED()
      unless $r->uri =~ m/^\/media\/.+/;
    my ($file) = $r->uri =~ m/^\/media\/([^\?]+)$/;
    
    my @args = ( "file=$file" );
    if( $r->args )
    {
      push @args, $r->args;
    }# end if()
    
    # Fixup the uri and args:
    $r->uri( '/handlers/MediaManager' );
    $r->args( join '&', @args );
    
    # Send the request on down the line to the next handler:
    return Apache2::Const::DECLINED();
  }# end if()
  
  return -1;
}# end handler()

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

Please visit the Apache2::ASP homepage at L<http://apache2-asp.no-ip.org/> to see examples
of Apache2::ASP in action.

=head1 AUTHOR

John Drago L<mailto:jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut
