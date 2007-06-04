
package Apache2::ASP::Application::MySQL;

use strict;
use base 'Apache2::ASP::Application';
use Storable qw( freeze thaw );
use DBI;


#==============================================================================
sub new
{
  my ($class) = @_;
  $class = ref($class) || $class;
  
  my $dbh = DBI->connect_cached( @{$ENV{APACHE2_ASP_STATE_DSN}} )
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
  
  my $dbh = DBI->connect_cached( @{$ENV{APACHE2_ASP_STATE_DSN}} )
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

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::Application::MySQL - MySQL-persisted Application state for Apache2::ASP

=head1 SYNOPSIS

In your httpd.conf:

  PerlSetEnv APACHE2_ASP_APPLICATION_MANAGER Apache2::ASP::Application::MySQL

That's it!  Now you're using C<Apache2::ASP::Application::MySQL> to manage all of 
your Application state in your Apache2::ASP web application.

B<NOTE:> - If you don't specify a value for C<$ENV{APACHE2_APPLICATION_MANAGER}>
then it will automatically default to C<Apache2::ASP::Application::MySQL>.

=head1 DESCRIPTION

C<Apache2::ASP::Application::MySQL> is both a reference implementation and the default
Application state manager for L<Apache2::ASP>.

Application state is unblessed, serialized via L<Storable> and written to the database
as a BLOB.

The data structure itself is simply a hashref.

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

John Drago L<mailto:jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut
