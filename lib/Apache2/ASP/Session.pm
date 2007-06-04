
package Apache2::ASP::Session;

use strict;
use Apache2::ASP::Config;

#==============================================================================
sub new
{
  my ($s, $SessionID, $r) = @_;
  
  die "new() not implemented";
}# end new()


#==============================================================================
sub save
{
  my $s = shift;
  
  die "save() not implemented";
}# end save()


#==============================================================================
sub Lock { 1 }


#==============================================================================
sub Unlock { 1 }


#==============================================================================
sub Abandon
{
  my $s = shift;
  
  delete $s->{$_} foreach grep { $_ ne 'SessionID' } keys(%$s);
  $s->save;
}# end Abandon()


#==============================================================================
sub DESTROY
{
  my $s = shift;
  $s->save();
  undef($s);
}# end DESTROY()

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::Session - Base class for Session state managers

=head1 DESCRIPTION

In the C<Apache2::ASP> web programming environment, the global C<$Session> object
is an instance of a subclass of C<Apache2::ASP::Session>.

Storing data in the C<$Session> object makes that data available to future requests
from the same client while that C<$Session> is still active.

=head1 SEE ALSO

Make sure to read up on L<Apache2::ASP::Session::MySQL> since it is the default
Session state manager.

=head1 AUTHOR

John Drago L<jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut
