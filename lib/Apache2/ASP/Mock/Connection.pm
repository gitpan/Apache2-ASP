
package Apache2::ASP::Mock::Connection;

use strict;
use warnings 'all';
use Apache2::ASP::Mock::ClientSocket;

sub new
{
  return bless { }, shift;
}# end new()


sub aborted
{
  0;
}# end aborted()


sub client_socket
{
  return Apache2::ASP::Mock::ClientSocket->new();
}# end client_socket()

1;# return true:

