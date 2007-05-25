
package Apache2::ASP::Application;

use strict;
use warnings;
use Storable qw( freeze thaw );
use DBI;
use Apache2::ASP::Config;

our $VERSION = 0.02;


#==============================================================================
sub new
{
  my ($class) = @_;
  $class = ref($class) || $class;
  
  my $dbh = DBI->connect_cached( @{$ENV{APACHE2_ASP_DSN}} )
    or die "Cannot connect to database: $DBI::errstr";
  my $sth = $dbh->prepare('SELECT * FROM asp_applications WHERE application_id = ?');
  $sth->execute( $ENV{HTTP_HOST} );
  
  my $rec = $sth->fetchrow_hashref;
  $sth->finish();
  
  # We either got a record or we didn't:
  if( $rec->{application_id} )
  {
    # We got a record - use it:
    return bless thaw( $rec->{application_data} ), $class;
  }
  else
  {
    # No record found - create a new application record:
    $sth = $dbh->prepare(<<EOF);
    INSERT INTO asp_applications (
      application_id,
      application_data
    )
    VALUES (
      ?, ?
    )
EOF
    $sth->execute(
      $ENV{HTTP_HOST},
      freeze(bless( {}, $class))
    );
    
    # Just start over now:
    return $class->new();
  }# end if()
}# end new()


#==============================================================================
sub save
{
  my ($s) = @_;
  
  my $dbh = DBI->connect_cached( @{$ENV{APACHE2_ASP_DSN}} )
    or die "Cannot connect to database: $DBI::errstr";
  my $sth = $dbh->prepare(<<EOF);
    UPDATE asp_applications SET
      application_data = ?
    WHERE application_id = ?
EOF
  my %obj = map { $_ => $s->{$_} } keys(%$s);
  $sth->execute(
    freeze( \%obj ),
    $ENV{HTTP_HOST}
  );
  $sth->finish();
  
  return $s;
}# end save()


#==============================================================================
sub DESTROY
{
  # XXX: Save data to persistent storage.
  my $s = shift;
  $s->save;
}# end DESTROY()

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::Application - Shared data for Apache2::ASP applications.

=head1 DESCRIPTION

The global C<$Application> object is an instance of C<Apache2::ASP::Application>.

Placing data inside the C<$Application> object makes it available to all future
requests to that web application.

Because the data is persisted within an SQL database, you can take advantage of
load-balanced servers without sacrificing the ability to share data across your
application.

=head1 DATABASE STRUCTURE

Applications are stored in a SQL database table with the following structure:

  CREATE TABLE asp_applications (
    application_id VARCHAR(100) PRIMARY KEY NOT NULL,
    application_data BLOB
  );

=head1 AUTHOR

John Drago L<jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut
