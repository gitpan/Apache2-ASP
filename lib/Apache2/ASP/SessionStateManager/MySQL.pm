
package Apache2::ASP::SessionStateManager::MySQL;

use strict;
use warnings 'all';

use base 'Apache2::ASP::SessionStateManager';


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

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::SessionStateManager::MySQL - MySQL backend for Apache2::ASP Session state

=head1 SYNOPSIS

In your apache2-asp-config.xml file:

  <config>
    <web_application>
    ...
      <session_state>
        <manager>Apache2::ASP::SessionStateManager::MySQL</manager>
        <dsn>DBI:mysql:DatabaseName:HostName</dsn>
        <username>Database-Username</username>
        <password>Database-Password</password>
      </session_state>
    ...

=head1 DESCRIPTION

This package uses a MySQL database to persist Session state for Apache2::ASP web applications.

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
