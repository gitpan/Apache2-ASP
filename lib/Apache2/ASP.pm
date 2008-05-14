
package Apache2::ASP;


use strict;
use warnings 'all';
use base 'Apache2::ASP::Base';

use Apache2::ASP::CGI;
use Apache2::ASP::UploadHook;

use APR::Table ();
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Directive ();
use Apache2::Connection ();
use Apache2::SubRequest ();
use Apache2::RequestUtil ();

use vars '$VERSION';
$VERSION = 1.41;

#==============================================================================
sub handler : method
{
  my ($class, $r) = @_;
  
  # We function best as an object:
  my $s = $class->SUPER::new( $ENV{APACHE2_ASP_CONFIG} );
  $s->{r} = $r;
  
  # What Apache2::ASP::Handler is going to handle this request?
  my $handler_class = $s->resolve_request_handler( $r->uri );
  if( $handler_class->isa('Apache2::ASP::UploadHandler') )
  {
    # We use the upload_hook functionality from Apache::Request
    # to process uploads:
    my $hook_obj = Apache2::ASP::UploadHook->new(
      asp           => $s,
      handler_class => $handler_class,
    );
    $s->{'q'} = Apache2::ASP::CGI->new( $r, sub { $hook_obj->hook( @_ ) } );
  }
  else
  {
    # Not an upload - normal CGI functionality will work fine:
    $s->{'q'} = Apache2::ASP::CGI->new( $r );
  }# end if()
  
  # Get our subref and execute it:
  $s->setup_request( $r, $s->{'q'} );
  my $status = eval { $s->execute() };
  if( $@ )
  {
    warn "ERROR AFTER CALLING \$handler->( ): $@";
    return $s->_handle_error( $@ );
  }# end if()
  
  # 0 = OK, everything else means errors of some kind:
  return $status eq '200' ? 0 : $status;
}# end handler()


#==============================================================================
sub _handle_error
{
  my ($s, $err) = @_;
  
  warn $err;
  $s->response->Clear();
  $s->global_asa->can('Script_OnError')->( $err );
  
  return 500;
}# end _handle_error()

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP - Perl extension for ASP on mod_perl2.

=head1 SYNOPSIS

=head2 In your ASP script

  <html>
    <body>
      <%= "Hello, World!" %>
      <br>
      <%
        for( 1...10 ) {
          $Response->Write( "Hello from ASP ($_)<br>" );
        }
      %>
    </body>
  </html>

=head1 INSTALLATION

For installation instructions, please refer to L<Apache2::ASP::Manual::Intro>.

=head1 INTRODUCTION

For an introduction to B<Apache2::ASP>, please see L<Apache2::ASP::Manual::Intro>.

=head1 DESCRIPTION

Apache2::ASP is a mod_perl2-specific subclass of L<Apache2::ASP::Base>.

=head1 METHODS

=head2 handler( $r )

Used by mod_perl - you can safely ignore this one for now.

If you are really interested in what goes on in there, please read the source.

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
