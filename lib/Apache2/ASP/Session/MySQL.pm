
package Apache2::ASP::Session::MySQL;

use strict;
use base 'Apache2::ASP::Session';
use DBI;
use Digest::MD5 'md5_hex';
use Storable qw( freeze thaw );
use HTTP::Date 'time2iso';


#==============================================================================
sub new
{
  my ($s, $SessionID, $r) = @_;
  
  my $dbh = DBI->connect_cached( @{$ENV{APACHE2_ASP_STATE_DSN}} )
    or die "Cannot connect to database: $DBI::errstr";
  
  if( $SessionID )
  {
    my $sth = $dbh->prepare_cached('SELECT * FROM asp_sessions WHERE session_id = ?');
    $sth->execute( $SessionID );
    my $rec = $sth->fetchrow_hashref;
    $sth->finish();
    my $data = thaw($rec->{session_data});
    
    my $class = ref($s) || $s;
    return bless( $data, $class );
  }
  else
  {
    if( $ENV{HTTP_HOST} )
    {
      if( ($SessionID) = $ENV{HTTP_COOKIE} =~ m/\bsession\-id\=([a-f0-9]+)\b/ )
      {
        my $class = ref($s) || $s;
        return $class->new( $SessionID, $r );
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
    
    my $class = ref($s) || $s;
    return $class->new( $SessionID, $r );
  }# end if()
}# end new()


#==============================================================================
sub save
{
  my $s = shift;
  
  my $dbh = DBI->connect_cached( @{$ENV{APACHE2_ASP_STATE_DSN}} )
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

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::Session::MySQL - MySQL-persisted Session state for Apache2::ASP

=head1 SYNOPSIS

In your httpd.conf:

  PerlSetEnv APACHE2_ASP_SESSION_MANAGER Apache2::ASP::Session::MySQL

That's it!  Now you're using C<Apache2::ASP::Session::MySQL> to manage all of 
your Session state in your Apache2::ASP web application.

B<NOTE:> - If you don't specify a value for C<$ENV{APACHE2_SESSION_MANAGER}>
then it will automatically default to C<Apache2::ASP::Session::MySQL>.

=head1 DESCRIPTION

C<Apache2::ASP::Session::MySQL> is both a reference implementation and the default
Session state manager for L<Apache2::ASP>.

Session state is unblessed, serialized via L<Storable> and written to the database
as a BLOB.

The data structure itself is simply a hashref.

Because the data is persisted within an SQL database, you can take advantage of
load-balanced servers without the need for "session affinity" at the network level.

=head1 DATABASE STRUCTURE

Sessions are stored in a SQL database table with the following structure:

  CREATE TABLE asp_sessions (
    session_id CHAR(32) PRIMARY KEY NOT NULL,
    session_data BLOB,
    created_on DATETIME,
    modified_on DATETIME
  );

=head1 AUTHOR

John Drago L<mailto:jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut
