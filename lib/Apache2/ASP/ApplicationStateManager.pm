
package Apache2::ASP::ApplicationStateManager;

use strict;
use warnings 'all';
use base 'Ima::DBI';
use Storable qw( freeze thaw );


#==============================================================================
sub new
{
  my ($class, $asp) = @_;
  
  my $s = bless {
    asp => $asp,
  }, $class;
  
  __PACKAGE__->set_db('Apps', 
    $s->{asp}->config->application_state->dsn,
    $s->{asp}->config->application_state->username,
    $s->{asp}->config->application_state->password, {
      RaiseError  => 1,
      AutoCommit  => 1,
    }
  ) unless __PACKAGE__->can('db_Apps');
  
  if( my $res = $s->retrieve )
  {
    return $res;
  }
  else
  {
    return $s->create;
  }# end if()
}# end new()


#==============================================================================
sub create
{
  my $s = shift;
  
  my $sth = $s->dbh->prepare(<<"");
    INSERT INTO asp_applications (
      application_id,
      application_data
    )
    VALUES (
      ?, ?
    )

  $sth->execute(
    $s->{asp}->config->application_name,
    freeze( {} )
  );
  $sth->finish();
  
  return $s->retrieve();
}# end create()


#==============================================================================
sub retrieve
{
  my $s = shift;
  
  my $sth = $s->dbh->prepare(<<"");
    SELECT application_data
    FROM asp_applications
    WHERE application_id = ?

  $sth->execute( $s->{asp}->config->application_name );
  my ($data) = $sth->fetchrow;
  $sth->finish();
  
  return unless $data;
  
  $data = thaw($data);
  $data->{asp} = $s->{asp};
  return bless $data, ref($s);
}# end retrieve()


#==============================================================================
sub save
{
  my $s = shift;
  
  my $sth = $s->dbh->prepare(<<"");
    UPDATE asp_applications SET
      application_data = ?
    WHERE application_id = ?

  my $data = { %$s };
  delete($data->{asp});
  delete($data->{dbh});
  $sth->execute(
    freeze( $data ),
    $s->{asp}->config->application_name
  );
  $sth->finish();
  
  1;
}# end save()


#==============================================================================
sub dbh
{
  my $s = shift;
  
  return $s->db_Apps;
}# end dbh()


#==============================================================================
sub DESTROY
{
  
}# end DESTROY()


1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::ApplicationStateManager - Base class for Application State Managers.

=head1 SYNOPSIS

Within your ASP script:

  <%
    $Application->{counter}++;
    $Response->Write("This website has had $Application->{counter} visitors since restart.");
  %>

=head1 DESCRIPTION

The global C<$Application> object is an instance of a subclass of C<Apache2::ASP::ApplicationStateManager>.

It is a blessed hash that is persisted within a database.  Use it to share information across all requests for
all users.

B<NOTE:> - do not store database connections within the C<$Application> object because they cannot be shared across
different processes/threads at this time.

=head1 METHODS

All methods are overridable, but come with sensible defaults.

=head2 new( $asp )

Returns a new C<Apache2::ASP::ApplicationStateManager> object, using C<$asp>.

C<$asp> should be a valid L<Apache2::ASP> object.

=head2 create( )

Creates a new Application.  Returns a new C<Apache2::ASP::ApplicationStateManager> object.

=head2 retrieve( )

Attempts to retrieve the current Application from the data source specified in the global config.

=head2 save( )

Attempts to save the current Application in the data source specified in the global config.

=head2 dbh( )

Returns a blessed L<DBI> connection to the data source specified in the global config.

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
