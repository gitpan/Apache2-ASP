
package Apache2::ASP::SessionStateManager;

use strict;
use warnings 'all';
use base 'Ima::DBI';
use Digest::MD5 'md5_hex';
use Storable qw( freeze thaw );
use HTTP::Date qw( time2iso str2time );
use Scalar::Util 'weaken';


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  my $s = bless {context => $args{context}}, $class;
  my $conn = $s->{context}->config->data_connections->session;
  
  local $^W = 0;
  __PACKAGE__->set_db('Sessions', $conn->dsn,
    $conn->username,
    $conn->password, {
      RaiseError  => 1,
      AutoCommit  => 1,
    }
  );
  
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
sub context
{
  Apache2::ASP::HTTPContext->current;
}# end context()


#==============================================================================
sub parse_session_id
{
  my ($s) = @_;
  
  my $cookiename = $s->context->config->data_connections->session->cookie_name;
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

  my $range_start = time() - ( $s->context->config->data_connections->session->session_timeout * 60 );
  my $sth = $s->dbh->prepare(<<"");
    SELECT COUNT(*)
    FROM asp_sessions
    WHERE session_id = ?
    AND modified_on BETWEEN ? AND ?

  $sth->execute( $id, time2iso($range_start), time2iso() );
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
  
  no warnings 'uninitialized';
  $s->{__signature} = md5_hex(
    join ":", 
      map { "$_:$s->{$_}" }
        grep { $_ ne '__signature' } sort keys(%$s)
  );
  
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
    SELECT session_data, modified_on
    FROM asp_sessions
    WHERE session_id = ?

  my $now = time2iso();
  $sth->execute( $id );
  my ($data, $modified_on) = $sth->fetchrow;
  $data = thaw($data);
  $sth->finish();

  if( time() - str2time($modified_on) >= ( $s->context->config->data_connections->session->session_timeout * 59 ) )
  {
    my $sth = $s->dbh->prepare(<<"");
    UPDATE asp_sessions SET
      modified_on = ?
    WHERE session_id = ?

    $sth->execute( time2iso(), $id );
    $sth->finish();
  }# end if()
  
  undef(%$s);
  $s = bless $data, ref($s);
  weaken($s);
  
  no warnings 'uninitialized';
  $s->{__signature} = md5_hex(
    join ":",
      map { "$_:$s->{$_}" } 
        grep { $_ ne '__signature' } sort keys(%$s)
  );
  
  return $s;
}# end retrieve()


#==============================================================================
sub save
{
  my ($s) = @_;
  
  no warnings 'uninitialized';
  return if $s->{__signature} eq md5_hex(
    join ":", map { "$_:$s->{$_}" }
                grep { $_ ne '__signature' } sort keys(%$s)
  );
  $s->{__signature} = md5_hex(
    join ":",
      map { "$_:$s->{$_}" } 
        grep { $_ ne '__signature' } sort keys(%$s)
  );
  
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


#=========================================================================
sub reset
{
  my ($s) = @_;
  
  # Remove everything *but* our important parts:
  my %saves = map { $_ => 1 } qw/ SessionID /;
  delete( $s->{$_} ) foreach grep { ! $saves{$_} } keys(%$s);
  $s->save;
}# end reset()


#==============================================================================
sub new_session_id
{
  md5_hex( rand() );
}# end new_session_id()


#==============================================================================
sub write_session_cookie
{
  my $s = shift;
  
  my $state = $s->context->config->data_connections->session;
  my $cookiename = $state->cookie_name;
  $s->context->response->AddHeader(
    'Set-Cookie' =>  "$cookiename=$s->{SessionID}; path=/; domain=" . $state->cookie_domain
  );
  
  # If we weren't given an HTTP cookie value, set it here.
  # This prevents subsequent calls to 'parse_session_id()' to fail:
  $ENV{HTTP_COOKIE} ||= '';
  if( $ENV{HTTP_COOKIE} !~ m/\b$cookiename\=.*?\b/ )
  {
    my @cookies = split /;/, $ENV{HTTP_COOKIE};
    push @cookies, "$cookiename=$s->{SessionID}";
    $ENV{HTTP_COOKIE} = join ';', @cookies;
  }# end if()
  
  1;
}# end write_session_cookie()


#==============================================================================
sub dbh
{
  my $s = shift;
  return $s->db_Sessions;
}# end dbh()


#==============================================================================
sub DESTROY
{
  my $s = shift;
  
  delete($s->{$_}) foreach keys(%$s);
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

TBD

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

