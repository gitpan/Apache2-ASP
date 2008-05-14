
package Apache2::ASP::UploadHandler;

use strict;
use base 'Apache2::ASP::Handler';
our $LastUpdate;

use vars qw(
  %modes
);

#==============================================================================
sub upload_start
{
  my ($s, $asp, $Upload) = @_;
  
  # Store the upload information in the Session for external retrieval:
  $LastUpdate = time();
  $asp->session->{$_} = $Upload->{$_}
    foreach keys(%$Upload);
  $asp->session->save;
}# end upload_start()


#==============================================================================
sub upload_end
{
  my ($s, $asp, $Upload) = @_;
  
  # Clear out the upload data from the Session:
  delete($asp->session->{$_})
    foreach keys(%$Upload);
  $asp->session->save;
}# end upload_end()


#==============================================================================
sub upload_hook
{
  my ($s, $asp, $Upload) = @_;
  
  # Since this method may be called several times per second, we only
  # want to save the Session state once per second:
  my $Diff = time() - $LastUpdate;
  if( $Diff >= 1 )
  {
    # Store everything in the session except for the data 
    # (since that could be too large to serialize quickly):
    $asp->session->{$_} = $Upload->{$_}
      foreach grep { $_ ne 'data' } keys(%$Upload);
    $asp->session->save;
    $LastUpdate = time();
  }# end if()
}# end upload_hook()

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::UploadHandler - Base class for Handlers that process file uploads

=head1 SYNOPSIS

Subclass L<Apache2::ASP::MediaManager> instead.

=head1 DESCRIPTION

This package provides the Apache2::ASP environment with the ability to process file uploads
B<while they are happening>.  Trigger points are exposed that are called at specific times 
during a file upload.

=head1 OVERRIDABLE METHODS

=head2 upload_start( $self, $asp, $Upload )

The C<$Upload> argument is an L<Apache2::ASP::UploadHookArgs> object.

Called B<just> before C<upload_hook()> is called for the first time.  If you need to do
any kind of setup or double-checking, this is the time to do it.

=head2 upload_end( $self, $asp, $Upload )

The C<$Upload> argument is an L<Apache2::ASP::UploadHookArgs> object.

Called B<just> after C<upload_hook()> is called for the B<last> time.  If you need to do
any kind of cleanup or redirect the user, this is the time to do it.

=head2 upload_hook( $self, $asp, $Upload )

The C<$Upload> argument is an L<Apache2::ASP::UploadHookArgs> object.

Called each time Apache reads in a chunk of bytes from the client during the upload.

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
