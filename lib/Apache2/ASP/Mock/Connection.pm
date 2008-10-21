
package Apache2::ASP::Mock::Connection;

use strict;
use warnings 'all';
use Apache2::ASP::Mock::ClientSocket;


#==============================================================================
sub new
{
  my ($class) = @_;
  
  my $s = bless {
    aborted => 0,
  }, $class;
  $s->{client_socket} = Apache2::ASP::Mock::ClientSocket->new( connection => $s );
  
  return $s;
}# end new()


#==============================================================================
sub aborted
{
  my ($s) = shift;
  @_ ? $s->{aborted} = shift : $s->{aborted};
}# end aborted()


#==============================================================================
sub client_socket
{
  $_[0]->{client_socket};
}# end client_socket()

1;# return true:

