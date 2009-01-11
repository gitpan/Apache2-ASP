
package Apache2::ASP::ModPerl;

use strict;
use warnings 'all';
use APR::Table ();
use APR::Socket ();
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::Connection ();
use Apache2::RequestUtil ();
use Apache2::ASP::HTTPContext ();
use Apache2::ASP::ModPerl2CGI ();
use Apache2::ASP::UploadHook;

local $Apache2::ASP::HTTPContext::ClassName = 'Apache2::ASP::HTTPContext';

#==============================================================================
sub handler : method
{
  my ($class, $r) = @_;
  
  my $context = $Apache2::ASP::HTTPContext::ClassName->new( );
  
  if( uc($ENV{REQUEST_METHOD}) eq 'POST' && lc($ENV{CONTENT_TYPE}) =~ m@multipart/form-data@ )
  {
    my $handler_class = $context->resolve_request_handler( $r->uri );
    unless( $ENV{QUERY_STRING} =~ m/mode\=[a-z0-9_]+/ )
    {
      die "All UploadHandlers require a querystring parameter 'mode' to be specified when uploading!";
    }# end unless()
    my $hook_obj = Apache2::ASP::UploadHook->new(
      handler_class => $handler_class,
    );
    $r->pnotes( content_length => $ENV{CONTENT_LENGTH} );
    
    # Magickally pass in a reference to the $cgi object before it exists.
    # Yes, this is Perl.
    our ( $R, $CGI ) = ($r, undef);
    my $cgi = $CGI = Apache2::ASP::ModPerl2CGI->new( $r, sub {
      $context->setup_request( $r, \$CGI) unless $context->_is_setup;
      $hook_obj->hook( @_ );
    });
    $context->execute;
    return 0;
  }
  else
  {
    my $cgi = Apache2::ASP::ModPerl2CGI->new( $r );
    $context->setup_request( $r, $cgi );
    $context->execute;
    return 0;
  }# end if()
}# end handler()

1;# return true:

