
package Apache2::ASP::UploadHandler;

use strict;
use base 'Apache2::ASP::Handler';
our $LastUpdate;


#==============================================================================
sub upload_start
{
  my ($s, $Session, $Request, $Response, $Server, $Application, $Upload) = @_;
  
  # Store the upload information in the Session for external retrieval:
  $LastUpdate = time();
  $Session->{$_} = $Upload->{$_}
    foreach keys(%$Upload);
  $Session->save;
}# end upload_start()


#==============================================================================
sub upload_end
{
  my ($s, $Session, $Request, $Response, $Server, $Application, $Upload) = @_;
  
  # Clear out the upload data from the Session:
  delete($Session->{$_})
    foreach keys(%$Upload);
  $Session->save;
}# end upload_end()


#==============================================================================
sub upload_hook
{
  my ($s, $Session, $Request, $Response, $Server, $Application, $Upload) = @_;
  
  # Since this method may be called several times per second, we only
  # want to save the Session state once per second:
  my $Diff = time() - $LastUpdate;
  if( $Diff >= 1 )
  {
    # Store everything in the session except for the data 
    # (since that could be too large to serialize quickly):
    $Session->{$_} = $Upload->{$_}
      foreach grep { $_ ne 'data' } keys(%$Upload);
    $Session->save;
    $LastUpdate = time();
  }# end if()
}# end upload_hook()

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::UploadHandler - Base class for Handlers that process file uploads

=head1 SYNOPSIS

Place the following code into C</handlers/MyUploader.pm>:

  package MyUploader;

  use strict;
  use base 'Apache2::ASP::UploadHandler';
  
  # Override any methods we need to:
  sub upload_end
  {
    my ($s, $Session, $Request, $Response, $Server, $Application, $Upload) = @_;
    shift(@_);
    $s->SUPER::upload_end( @_ );
    
    $Response->Redirect("/index.asp?status=done");
  }# end upload_end()
  
  1;# return true:

Then, create a web pages with a form that uploads a file to C</handlers/MyUploader>:

  <html>
  ...
  <form method="POST" enctype="multipart/form-data" action="/handlers/MyUploader">
    <input type="file" name="filename">
    <input type="submit" value="Click Here to Upload">
  </form>
  ...
  </html>

After the upload has finished, "MyUploader" will redirect you to C</index.asp?status=done> 
(where you might display a message of some kind).

=head1 DESCRIPTION

This package provides the Apache2::ASP environment with the ability to process file uploads
B<while they are happening>.  Through the use of L<libapreq2> we expose trigger points that
will be called at specific times during a file upload.

=head1 OVERRIDABLE METHODS

=head2 upload_start( $self, $Session, $Request, $Response, $Server, $Application, $Upload )

Called B<just> before C<upload_hook()> is called for the first time.  If you need to do
any kind of setup or double-checking, this is the time to do it.

=head2 upload_end( $self, $Session, $Request, $Response, $Server, $Application, $Upload )

Called B<just> after C<upload_hook()> is called for the B<last> time.  If you need to do
any kind of cleanup or redirect the user, this is the time to do it.

=head2 upload_hook( $self, $Session, $Request, $Response, $Server, $Application, $Upload )

Called each time Apache reads in a chunk of bytes from the client during the upload.

=head1 ARGUMENTS

All methods - C<upload_start()>, C<upload_end()> and C<upload_hook()> are called with the
same arguments.  They are listed here:

=head2 $Session

The global C<$Session> object.  See L<Apache2::ASP::Session> for details.

=head2 $Request

The global C<$Request> object.  See L<Apache2::ASP::Request> for details.

=head2 $Response

The global C<$Response> object.  See L<Apache2::ASP::Response> for details.

=head2 $Server

The global C<$Server> object.  See L<Apache2::ASP::Server> for details.

=head2 $Application

The global C<$Application> object.  See L<Apache2::ASP::Application> for details.

=head2 $Upload

The C<$Upload> argument is a hashref with the following structure:

  $VAR1 = {
    'upload'              => APR::Request::Param object,
    'content_length'      => 5333399,
    'percent_complete'    => '99.99',
    'data'                => 'The data that was received by the server in this "chunk"',
    'total_expected_time' => 3,
    'elapsed_time'        => '3.04842114448547',
    'time_remaining'      => 0,
    'length_received'     => 0,
  };

In an attempt to explain this in more detail, each element is listed below:

=head3 upload

An L<APR::Request::Param> object.  Use this object to retrieve information about the 
uploaded file (i.e. filehandle, MIME type, etc).

=head3 content_length

The size of the entire HTTP request as specified by C<$ENV{CONTENT_LENGTH}>.

=head3 percent_complete

A float that indicates the percent of the upload we have received so far.

=head3 data

The string of bytes that was received from the client in the most recent chunk.

=head3 total_expected_time

Total number of seconds we expect this entire upload operation to take.

=head3 elapsed_time

Total number of seconds since we started this upload.

=head3 time_remaining

Total number of seconds remaining for this upload.

=head3 length_received

Total number of bytes we have received from the client at this point.

=head1 HOW TO SAVE UPLOADED FILE DATA

Of course the whole point of uploading files is to save them on the server.

Do it like this:

  # Get our filehandle:
  my $in_filehandle = $Upload->{upload}->upload_fh;
  
  # Create a local file to write to:
  open my $out_filehandle, '>', '/path/to/save/file';
  
  # Make MSWin32 happy:
  binmode($out_filehandle);
  binmode($in_filehandle);
  
  # Read from one filehandle and write to the other:
  while( my $line = <$in_filehandle> )
  {
    print $out_filehandle $line;
  }# end while()
  
  # Finish up:
  close($in_filehandle);
  close($out_filehandle);

=head1 AUTHOR

John Drago L<jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut
