
package Apache2::ASP::HTTPContext::FilterResolver;

use strict;
use warnings 'all';


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  return bless \%args, $class;
}# end new()


#==============================================================================
sub context { Apache2::ASP::HTTPContext->current }


#==============================================================================
sub resolve_request_filters
{
  my ($s, $uri) = @_;
  
  ($uri) = split /\?/, $uri;
  return grep {
    if( my $pattern = $_->uri_match )
    {
      $uri =~ m/$pattern/
    }
    else
    {
      $uri eq $_->uri_equals;
    }# end if()
  } $s->context->config->web->request_filters;  
}# end resolve_request_filters()

1;# return true:

