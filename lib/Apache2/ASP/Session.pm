
package Apache2::ASP::Session;

our $VERSION = 0.07;

use strict;
use DBI;
use Digest::MD5 'md5_hex';
use Storable qw( freeze thaw );
use Apache2::ASP::Config;
use HTTP::Date 'time2iso';


#==============================================================================
sub new
{
  my ($s, $SessionID, $r) = @_;
  
  my $dbh = DBI->connect_cached( @{$ENV{APACHE2_ASP_DSN}} )
    or die "Cannot connect to database: $DBI::errstr";
  
  if( $SessionID )
  {
    my $sth = $dbh->prepare_cached('SELECT * FROM asp_sessions WHERE session_id = ?');
    $sth->execute( $SessionID );
    my $rec = $sth->fetchrow_hashref;
    $sth->finish();
    my $data = thaw($rec->{session_data});
    
    return bless( $data, 'Apache2::ASP::Session' );
  }
  else
  {
    if( $ENV{HTTP_HOST} )
    {
      if( ($SessionID) = $ENV{HTTP_COOKIE} =~ m/session\-id\=([a-f0-9]+)/ )
      {
        return __PACKAGE__->new( $SessionID, $r );
      }
      else
      {
        $SessionID = md5_hex(time() . ( rand() + rand() ));
        my $headers = $r->headers_out;
        $headers->{'Set-Cookie'} = "$ENV{APACHE2_ASP_SESSION_COOKIE_NAME}=$SessionID; path=/; domain=$ENV{APACHE2_ASP_SESSION_COOKIE_DOMAIN}";
        $r->headers_out( $headers );
      }# end if()
    }
    else
    {
      $SessionID = md5_hex(time() . ( rand() + rand() ));
    }# end if()
    my $data = freeze({ SessionID => $SessionID });
    my $sth = $dbh->prepare_cached(q{
      INSERT INTO asp_sessions ( session_id, session_data, created_on, modified_on )
      VALUES ( ?, ?, ?, ? )
    });
    $sth->execute(
      $SessionID,
      $data,
      time2iso(),
      time2iso()
    );
    $sth->finish();
    
    return __PACKAGE__->new( $SessionID, $r );
  }# end if()
}# end new()


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

Apache2::ASP::Session - Database-persisted Session data for Apache2::ASP

=head1 DESCRIPTION

In the C<Apache2::ASP> web programming environment, the global C<$Session> object
is an instance of C<Apache2::ASP::Session>.

Storing data in the C<$Session> object makes that data available to future requests
from the same client while that C<$Session> is still active.

Because the data is persisted within an SQL database, you can take advantage of
load-balanced servers without the need for "session affinity" at the network level.

=head1 DATABASE STRUCTURE

Sessions are stored in a SQL database table with the following structure:

  CREATE TABLE sessions (
    session_id CHAR(32) PRIMARY KEY NOT NULL,
    session_data BLOB,
    created_on DATETIME,
    modified_on DATETIME
  );

=head1 AUTHOR

John Drago L<jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut
