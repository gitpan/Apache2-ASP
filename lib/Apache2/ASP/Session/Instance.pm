
package Apache2::ASP::Session::Instance;

use strict;
use DBI;
use Storable qw(freeze);
use HTTP::Date 'time2iso';

our $VERSION = 0.03;


#==============================================================================
sub save
{
  my $s = shift;
  
  my $dbh = DBI->connect_cached( @{$ENV{APACHE2_ASP_DSN}} )
    or die "Cannot connect to database: $DBI::errstr";
  my $sth = $dbh->prepare_cached(q{
    UPDATE asp_sessions SET
      session_data = ?,
      modified_on = ?
    WHERE session_id = ?
  });
  my %obj = map { $_ => $s->{$_} } keys(%$s);
  $sth->execute(
    freeze(\%obj),
    time2iso(),
    $obj{SessionID}
  );
  $sth->finish();
  return $s;
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

Apache2::ASP::Session::Instance - Database-persisted Session data for Apache2::ASP

=head1 DESCRIPTION

In the C<Apache2::ASP> web programming environment, the global C<$Session> object
is an instance of C<Apache2::ASP::Session::Instance>.

Storing data in the C<$Session> object makes that data available to future requests
from the same client while that C<$Session> is still active.

Because the data is persisted within an SQL database, you can take advantage of
load-balanced servers without the need for "session affinity" at the network level.

=head1 EXAMPLES

=head1 PUBLIC METHODS

=head2 save( )

Stores the contents of C<$Session> in the database.

=head2 Abandon( )

Deletes all data from the C<$Session> object.  Returns an empty C<$Session> object.

=head2 Lock( )

Does nothing.  Returns C<1>.

Maintained for backwards-compatibility with C<Apache::ASP>.

=head2 Unlock( )

Does nothing.  Returns C<1>.

Maintained for backwards-compatibility with C<Apache::ASP>.

=head1 AUTHOR

John Drago L<jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut

