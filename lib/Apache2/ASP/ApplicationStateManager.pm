
package Apache2::ASP::ApplicationStateManager;

use strict;
use warnings 'all';
use Storable qw( freeze thaw );
use DBI;
use Scalar::Util 'weaken';
use base 'Ima::DBI';
use Digest::MD5 'md5_hex';

our %DBI_OPTIONS = (
  FetchHashKeyName    => 'NAME_lc',
  ShowErrorStatement  => 1,
  ChopBlanks          => 1,
  AutoCommit          => 1,
  RaiseError          => 1,
  RootClass           => 'DBIx::ContextualFetch',
);

#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  my $s = bless { }, $class;

  my $conn = $s->context->config->data_connections->application;
  local $^W = 0;
  __PACKAGE__->set_db('Main', $conn->dsn,
    $conn->username,
    $conn->password,
#    \%DBI_OPTIONS
  );
  $s->db_Main->{AutoCommit} = 1;
  
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
sub context
{
  $Apache2::ASP::HTTPContext::ClassName->current;
}# end context()


#==============================================================================
sub create
{
  my $s = shift;
  
  local $s->db_Main->{AutoCommit} = 1;
  my $sth = $s->db_Main->prepare(<<"");
    INSERT INTO asp_applications (
      application_id,
      application_data
    )
    VALUES (
      ?, ?
    )

  $sth->execute(
    $s->context->config->web->application_name,
    freeze( {} )
  );
  $sth->finish();
  
  return $s->retrieve();
}# end create()


#==============================================================================
sub retrieve
{
  my $s = shift;
  
  my $sth = $s->dbh->prepare_cached(<<"");
    SELECT application_data
    FROM asp_applications
    WHERE application_id = ?

  $sth->execute( $s->context->config->web->application_name );
  my ($data) = $sth->fetchrow;
  $sth->finish();
  
  return unless $data;
  
  $data = thaw($data);
  undef(%$s);
  $s = bless $data, ref($s);
  
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
  my $s = shift;

  no warnings 'uninitialized';
  return if $s->{__signature} eq md5_hex(
    join ":",
      map { "$_:$s->{$_}" }
        grep { $_ ne '__signature' } sort keys(%$s)
  );
  $s->{__signature} = md5_hex(
    join ":",
      map { "$_:$s->{$_}" } 
        grep { $_ ne '__signature' } sort keys(%$s)
  );
  
  local $s->db_Main->{AutoCommit} = 1;
  my $sth = $s->db_Main->prepare_cached(<<"");
    UPDATE asp_applications SET
      application_data = ?
    WHERE application_id = ?

  my $data = { %$s };
  delete($data->{__signature} );
  $sth->execute(
    freeze( $data ),
    $s->context->config->web->application_name
  );
  $sth->finish();
  
  1;
}# end save()


#==============================================================================
sub dbh
{
  my $s = shift;
  return $s->db_Main;
}# end dbh()


#==============================================================================
sub DESTROY
{
  my $s = shift;
  
  delete($s->{$_}) foreach keys(%$s);
}# end DESTROY()

1;# return true:

