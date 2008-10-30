
package Apache2::ASP::UploadHandler;

use strict;
use base 'Apache2::ASP::HTTPHandler';
our $LastUpdate;
our $LastPercent;


#==============================================================================
sub upload_start
{
  my ($s, $context, $Upload) = @_;
  
  return unless $Upload;
  # Store the upload information in the Session for external retrieval:
  $LastUpdate = time();
  $LastPercent = $Upload->{percent_complete} || 0;
  $context->session->{$_} = $Upload->{$_}
    foreach keys(%$Upload);
  $context->session->save;
}# end upload_start()


#==============================================================================
sub upload_end
{
  my ($s, $context, $Upload) = @_;
  
  # Clear out the upload data from the Session:
  $Upload->{percent_complete} = 100;
  delete($context->session->{$_})
    foreach keys(%$Upload);
  $context->session->save;
}# end upload_end()


#==============================================================================
sub upload_hook
{
  my ($s, $context, $Upload) = @_;
  
  # Since this method may be called several times per second, we only
  # want to save the Session state once per second:
  my $Diff = time() - $LastUpdate;
  my $PercentDiff = $Upload->{percent_complete} - $LastPercent;
  if( $Diff >= 2 || $PercentDiff >= 10 )
  {
#warn "SAVING SESSION!: $Diff $Upload->{percent_complete}%";
    # Store everything in the session except for the data 
    # (since that could be too large to serialize quickly):
    $context->session->{$_} = $Upload->{$_}
      foreach grep { $_ ne 'data' } keys(%$Upload);
    $context->session->save;
    $LastUpdate = time();
    $LastPercent = $Upload->{percent_complete};
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

=head2 upload_start( $self, $context, $Upload )

The C<$Upload> argument is an L<Apache2::ASP::UploadHookArgs> object.

Called B<just> before C<upload_hook()> is called for the first time.  If you need to do
any kind of setup or double-checking, this is the time to do it.

=head2 upload_end( $self, $context, $Upload )

The C<$Upload> argument is an L<Apache2::ASP::UploadHookArgs> object.

Called B<just> after C<upload_hook()> is called for the B<last> time.  If you need to do
any kind of cleanup or redirect the user, this is the time to do it.

=head2 upload_hook( $self, $context, $Upload )

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
