
package Apache2::ASP::SessionStateManager;

use strict;
use warnings 'all';
use DBI;
use Digest::MD5 'md5_hex';
use DateTime::Duration;
use Storable qw( freeze thaw );
use HTTP::Date 'time2iso';
our ($_asp, $_dbh);


#==============================================================================
sub new
{
  my ($class, $asp) = @_;
  
  my $s = bless {}, $class;
  $_asp = $asp;
  
  # Setup our maximum session timeout:
  my $dt = DateTime::Duration->new( minutes => $_asp->config->session_state->session_timeout );
  $s->{interactive_timeout} = join( ':', map { $_ < 10 ? "0$_" : $_ } $dt->in_units("hours", "minutes", "seconds") );
  
  # Prepare our Session:
  if( my $id = $s->parse_session_id() )
  {
    if( $s->verify_session_id( $id ) )
    {
      $s->{SessionID} = $id;
      return $s->retrieve( $id );
    }
    else
    {
      $s->{SessionID} = $s->new_session_id();
      $s->write_session_cookie();
      return $s->create( $s->{SessionID} );
    }# end if()
  }
  else
  {
    $s->{SessionID} = $s->new_session_id();
    $s->write_session_cookie();
    return $s->create( $s->{SessionID} );
  }# end if()
}# end new()


#==============================================================================
sub parse_session_id
{
  my ($s) = @_;
  
  my $cookiename = $_asp->config->session_state->cookie_name;
  no warnings 'uninitialized';
  if( my ($id) = $ENV{HTTP_COOKIE} =~ m/\b$cookiename\=([a-f0-9]+)\b/ )
  {
    return $id;
  }
  else
  {
    return;
  }# end if()
}# end parse_session_id()


#==============================================================================
# Returns true if the session exists and has not timed out:
sub verify_session_id
{
  my ($s, $id) = @_;
  
  my $sth = $s->dbh->prepare(<<"");
    SELECT COUNT(*)
    FROM asp_sessions
    WHERE session_id = ?
    AND ADDTIME(modified_on, ?) >= NOW()

  $sth->execute( $id, $s->{interactive_timeout} );
  my ($active) = $sth->fetchrow();
  $sth->finish();
  
  return $active;
}# end verify_session_id()


#==============================================================================
sub create
{
  my ($s, $id) = @_;
  
  my $sth = $s->dbh->prepare(<<"");
    INSERT INTO asp_sessions (
      session_id,
      session_data,
      created_on,
      modified_on
    )
    VALUES (
      ?, ?, ?, ?
    )

  my $now = time2iso();
  my %clone = %$s;
  
  $sth->execute(
    $id,
    freeze( \%clone ),
    $now,
    $now,
  );
  $sth->finish();
  
  return $s->retrieve( $id );
}# end create()


#==============================================================================
sub retrieve
{
  my ($s, $id) = @_;
  
  my $sth = $s->dbh->prepare(<<"");
    SELECT session_data
    FROM asp_sessions
    WHERE session_id = ?

  $sth->execute( $id );
  my ($data) = thaw( $sth->fetchrow );
  $sth->finish();
  
  return bless $data, ref($s);
}# end retrieve()


#==============================================================================
sub save
{
  my ($s) = @_;
  
  my $sth = $s->dbh->prepare(<<"");
    UPDATE asp_sessions SET
      session_data = ?,
      modified_on = ?
    WHERE session_id = ?

  my %clone = %$s;
  my $data = freeze( \%clone );
  $sth->execute( $data, time2iso(), $s->{SessionID} );
  $sth->finish();
  
  1;
}# end save()


#==============================================================================
sub new_session_id
{
  md5_hex( rand() );
}# end new_session_id()


#==============================================================================
sub write_session_cookie
{
  my $s = shift;
  
  my $state = $_asp->config->session_state;
  $_asp->response->AddHeader(
    'Set-Cookie' => $state->cookie_name . "=$s->{SessionID}; path=/; domain=" . $state->cookie_domain
  );
  
  1;
}# end write_session_cookie()


#==============================================================================
sub dbh
{
  my $s = shift;
  
  return $_dbh
    if $_dbh && eval { $_dbh->ping };
  
  return $_dbh = DBI->connect(
    $_asp->config->session_state->dsn,
    $_asp->config->session_state->username,
    $_asp->config->session_state->password, {
      RaiseError  => 1,
      AutoCommit  => 1,
    }
  );
}# end dbh()


#==============================================================================
sub DESTROY
{
  
}# end DESTROY()

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::SessionStateManager - Base class for Session State Managers.

=head1 SYNOPSIS

Within your ASP script:

  <%
    $Session->{counter}++;
    $Response->Write("You have viewed this page $Session->{counter} times.");
  %>

=head1 DESCRIPTION

The global C<$Session> object is an instance of a subclass of C<Apache2::ASP::SessionStateManager>.

It is a blessed hash that is persisted within a database.  Use it to share information across all requests for
all users.

B<NOTE:> - do not store database connections within the C<$Session> object because they cannot be shared across
different processes/threads at this time.

=head1 METHODS

=head2 new( $asp )

Returns a new C<Apache2::ASP::SessionStateManager> object, using C<$asp>.

C<$asp> should be a valid L<Apache2::ASP> object.

=head2 parse_session_id( )

=head2 verify_session_id( $id )

=head2 create( $id )

Creates a new Session.  Returns a new C<Apache2::ASP::SessionStateManager> object.

=head2 retrieve( $id )

Attempts to retrieve the Session by that ID from the database.

=head2 save( )

Stores the session in the database.

=head2 new_session_id( )

Generates a new session id.  Currently this is a 32-character random string of hexadecimal digits (0-9, a-f).

=head2 write_session_cookie( )

Adds the 'Set-Cookie' header to the outgoing HTTP headers.

=head2 dbh( )

Returns a blessed L<DBI> connection to the data source specified in the global config.

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
