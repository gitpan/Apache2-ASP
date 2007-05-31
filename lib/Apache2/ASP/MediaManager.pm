
package Apache2::ASP::MediaManager;

use strict;
use base 'Apache2::ASP::UploadHandler';
use MIME::Types;

my $mimetypes = MIME::Types->new();


#==============================================================================
sub run
{
  my ($s, $Session, $Request, $Response, $Server, $Application) = @_;
  
  shift(@_);
  my $filename = $s->compose_download_file_path( @_ );
  my $file = $s->compose_download_file_name( @_ );
  
  # Find its MIME type and set our 'ContentType' value:
  my ($ext) = $filename =~ m/.*?\.([^\.]+)$/;
  $ext ||= 'txt';
  my $type = $mimetypes->mimeTypeOf( $ext );
  $Response->{ContentType} = $type;
  
  # Make sure the file exists:
  -f $filename or return 404;
  
  # Call our extension hooks:
  if( $Request->Form('mode') eq 'delete' )
  {
    $s->before_delete($Session, $Request, $Response, $Server, $Application)
      or return;
    $s->delete_file( $Session, $Request, $Response, $Server, $Application, $filename );
    $s->after_delete($Session, $Request, $Response, $Server, $Application);
    return;
  }# end if()
  
  # Get the readable filehandle:
  my $ifh = $s->open_file_for_reading( $Session, $Request, $Response, $Server, $Application, $filename );
  
  # Call our before- hook:
  $s->before_download( $Session, $Request, $Response, $Server, $Application )
    or return;
  
  # Send any HTTP headers:
  $s->send_http_headers($Session, $Request, $Response, $Server, $Application, $filename, $file, $ext);
  
  # Print the file out:
  while( my $line = <$ifh> )
  {
    $Response->Write( $line );
    $Response->Flush;
  }# end while()
  
  # Done!
  close($ifh);
  
  # Call our after- hook:
  $s->after_download( $Session, $Request, $Response, $Server, $Application );
}# end run()


#==============================================================================
sub send_http_headers
{
  my ($s, $Session, $Request, $Response, $Server, $Application, $filename, $file, $ext) = @_;
  
  # Send the 'content-length' header:
  $Response->AddHeader( 'Content-Length' => -s $filename );
  
  # PDF files should force the "Save file as..." dialog:
  my $disposition = (lc($ext) eq 'pdf') ? 'attachment' : 'inline';
  $Response->AddHeader( 'content-disposition' => "$disposition;filename=" . $file );
}# end send_http_headers()


#==============================================================================
sub delete_file
{
  my ($s, $Session, $Request, $Response, $Server, $Application, $filename) = @_;
  
  unlink( $filename )
    or die "Cannot delete file '$filename' from disk: $!";
}# end delete_file()


#==============================================================================
sub open_file_for_writing
{
  my ($s, $Session, $Request, $Response, $Server, $Application, $filename) = @_;
  
  # Try to open the file for writing:
  open my $ifh, '>', $filename
    or die "Cannot open file '$filename' for writing: $!";
  binmode($ifh);
  
  return $ifh;
}# end open_file_for_writing()


#==============================================================================
sub open_file_for_reading
{
  my ($s, $Session, $Request, $Response, $Server, $Application, $filename) = @_;
  
  # Try to open the file for reading:
  open my $ifh, '<', $filename
    or die "Cannot open file '$filename' for reading: $!";
  binmode($ifh);
  
  return $ifh;
}# end open_file_for_reading()


#==============================================================================
sub open_file_for_appending
{
  my ($s, $Session, $Request, $Response, $Server, $Application, $filename) = @_;
  
  # Try to open the file for appending:
  open my $ifh, '>>', $filename
    or die "Cannot open file '$filename' for appending: $!";
  binmode($ifh);
  
  return $ifh;
}# end open_file_for_appending()


#==============================================================================
sub compose_download_file_path
{
  my ($s, $Session, $Request, $Response, $Server, $Application) = @_;
  
  # Compose the local filename:
  my $file = $Request->Form->{file};
  my $filename = $ENV{APACHE2_MEDIA_MANAGER_UPLOAD_ROOT} . '/' . $file;
  
  return $filename;
}# end compose_file_path()


#==============================================================================
sub compose_download_file_name
{
  my ($s, $Session, $Request, $Response, $Server, $Application) = @_;
  
  # Compose the local filename:
  my $file = $Request->Form->{file};
  
  return $file;
}# end compose_file_name()


#==============================================================================
sub compose_upload_file_name
{
  my ($s, $Session, $Request, $Response, $Server, $Application, $Upload) = @_;
  
  my ($filename) = $Upload->{upload}->upload_filename =~ m/.*[\\\/]([^\/\\]+)$/;
  if( ! $filename )
  {
    $filename = $Upload->{upload}->upload_filename;
  }# end if()
  
  return $filename;
}# end compose_upload_file_name()


#==============================================================================
sub compose_upload_file_path
{
  my ($s, $Session, $Request, $Response, $Server, $Application, $Upload, $filename) = @_;
  
  return "$ENV{APACHE2_MEDIA_MANAGER_UPLOAD_ROOT}/$filename";
}# end compose_upload_file_path()


#==============================================================================
sub upload_start
{
  my ($s, $Session, $Request, $Response, $Server, $Application, $Upload) = @_;
  shift(@_);
  $s->SUPER::upload_start( @_ );
  
  my $filename = $s->compose_upload_file_name( @_ );
  
  # Depending on the 'mode' parameter, we do different things:
  local $_ = $Request->Form('mode');
  if( /^create$/ )
  {
    $s->before_create($Session, $Request, $Response, $Server, $Application, $Upload)
      or return;
  }
  elsif( /^update$/ )
  {
    $s->before_update($Session, $Request, $Response, $Server, $Application, $Upload)
      or return;
  }
  else
  {
    die "Unknown mode: '$_'";
  }# end if()
  
  # Make sure we can open the file for writing:
  my $target_file = $s->compose_upload_file_path( $Session, $Request, $Response, $Server, $Application, $Upload, $filename);
  
  # Open the file for writing:
  my $ofh = $s->open_file_for_writing($Session, $Request, $Response, $Server, $Application, $target_file);
  
  # Done with the filehandle:
  close($ofh);
  
  # Store some information for later:
  $Server->{r}->pnotes( filename => $target_file );
  $Server->{r}->pnotes( download_file => $filename );
}# end upload_start()


#==============================================================================
sub upload_hook
{
  my ($s, $Session, $Request, $Response, $Server, $Application, $Upload) = @_;
  shift(@_);
  $s->SUPER::upload_hook( @_ );
  
  my $filename = $Server->{r}->pnotes( 'filename' )
    or die "Couldn't get pnotes 'filename'";
  
  my $ofh = $s->open_file_for_appending($Session, $Request, $Response, $Server, $Application, $filename);
  print $ofh $Upload->{data};
  close($ofh);
}# end upload_hook()


#==============================================================================
sub upload_end
{
  my ($s, $Session, $Request, $Response, $Server, $Application, $Upload) = @_;
  shift(@_);
  $s->SUPER::upload_end( @_ );
  
  # Return information about what we just did:
  my $info = {
    new_file      => $Server->{r}->pnotes( 'filename' ),
    filename_only => $Server->{r}->pnotes( 'download_file' ),
    link_to_file  => "/media/" . $Server->{r}->pnotes( 'download_file' ),
  };
  $Upload->{$_} = $info->{$_} foreach keys(%$info);
  
  # Depending on the 'mode' parameter, we do different things:
  local $_ = $Request->Form('mode');
  if( /^create$/ )
  {
    $s->after_create($Session, $Request, $Response, $Server, $Application, $Upload);
  }
  elsif( /^update$/ )
  {
    $s->after_update($Session, $Request, $Response, $Server, $Application, $Upload);
  }
  else
  {
    die "Unknown mode: '$_'";
  }# end if()
}# end upload_end()


#==============================================================================
sub before_download
{
  my ($s, $Session, $Request, $Response, $Server, $Application) = @_;
  
}# end before_download()


#==============================================================================
sub after_download
{
  my ($s, $Session, $Request, $Response, $Server, $Application) = @_;
  
}# end after_download()


#==============================================================================
sub before_create
{
  my ($s, $Session, $Request, $Response, $Server, $Application, $Upload) = @_;
  
}# end before_create()


#==============================================================================
sub before_update
{
  my ($s, $Session, $Request, $Response, $Server, $Application, $Upload) = @_;
  
}# end before_update()


#==============================================================================
sub after_create
{
  my ($s, $Session, $Request, $Response, $Server, $Application, $Upload) = @_;
  
}# end after_create()


#==============================================================================
sub after_update
{
  my ($s, $Session, $Request, $Response, $Server, $Application, $Upload) = @_;
  
}# end after_update()


#==============================================================================
sub before_delete
{
  my ($s, $Session, $Request, $Response, $Server, $Application) = @_;
  
}# end before_delete()


#==============================================================================
sub after_delete
{
  my ($s, $Session, $Request, $Response, $Server, $Application) = @_;
  
}# end after_delete()

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::MediaManager - Instant file management for Apache2::ASP applications

=head1 SYNOPSIS

First, add the following to your httpd.conf file:

  PerlSetEnv APACHE2_MEDIA_MANAGER_UPLOAD_ROOT /usr/local/dstack/MEDIA
  
  # Configuration for MediaManager:
  RedirectMatch ^/media/(.*) /handlers/MyMediaManager?file=$1

Then, in your /handlers directory for your Apache2::ASP website, make a new
file named "MyMediaManager.pm":

  package MyMediaManager;
  
  use strict;
  use base 'Apache2::ASP::MediaManager';
  
  #==============================================================================
  # Make sure the user is authorized to upload files to this server:
  sub before_create
  {
    my ($s, $Session, $Request, $Response, $Server, $Application, $Upload) = @_;
    
    my $user = my_user_finding_method();
    if( ! ( $user && $user->can_upload_files() ) )
    {
      return 1;
    }
    else
    {
      $Session->{message} = "You are not authorized to upload files";
      $Response->Redirect("/unauthorized.asp");
      return 0;
    }# end if()
  }# end before_create()
  
  #==============================================================================
  # Redirect the user to a "thank you" page:
  sub after_create
  {
    my ($s, $Session, $Request, $Response, $Server, $Application, $Upload) = @_;
    
    # Do whatever we want to the new file on disk:
    # recombobulate( $Upload->{new_file} );
    
    # Store a friendly message:
    $Session->{message} = "Your upload was successful";
    
    # Redirect the user to your "Thank you" page:
    $Response->Redirect( "/upload_completed.asp?file=$Upload->{link_to_file}" );
  }# end after_create()
  
  1;# return true:

Now, when you want to upload files, just point the upload form to
/handlers/MyMediaManager, like so:

  <html>
  ...
  <form method="POST" enctype="multipart/form-data" action="/handlers/MyMediaManager">
    <!-- This "mode" parameter tells the 
    <input type="hidden" name="mode" value="create">
    <input type="file" name="filename">
    <input type="submit" value="Click Here to Upload">
  </form>
  ...
  </html>

=head1 DESCRIPTION

Almost any web application will eventually require some kind of file-upload functionality.

Apache2::ASP aims to deliver this right out of the box.  Since all the file-upload work is
already done, all you need to do is subclass C<Apache2::ASP::MediaManager> and go from there
(as shown in the synopsis above).

=head1 OVERRIDABLE METHODS

=head2 before_create($s, $Session, $Request, $Response, $Server, $Application, $Upload)

Called just before we begin reading data from the client.  This would be a good time to verify
that the user is allowed to upload files.

=head2 after_create($s, $Session, $Request, $Response, $Server, $Application, $Upload)

Called just after we have finished writing data to the new file.  This would be a good 
time to do any post-processing on the file (i.e. store metadata about the upload in a 
database).

=head2 before_update($s, $Session, $Request, $Response, $Server, $Application, $Upload)

Called just before we begin reading data from the client.  This would be a good time to verify
that the user is allowed to update this file.

=head2 after_update($s, $Session, $Request, $Response, $Server, $Application, $Upload)

Called just after we have finished writing data to the existing file.  This would be a good 
time to do any post-processing on the file (i.e. store metadata about the upload in a 
database, delete any cached thumbnails, etc.).

=head2 before_delete($s, $Session, $Request, $Response, $Server, $Application)

Called just before we delete the file from disk.  This would be a good time to verify
that the user is allowed to delete this file.

=head2 after_delete($s, $Session, $Request, $Response, $Server, $Application)

Called just after we delete the file from disk.  This would be a good time to do any
post-processing (i.e. delete any metadata about the file in a database, delete any cached 
thumbnails, etc.)

=head2 before_download($s, $Session, $Request, $Response, $Server, $Application)

Called just after we have verified that the file exists and that we can open it for reading,
but before we have printed any data to the client.  This would be a good time to verify that
the user is allowed to download this file.

=head2 after_download($s, $Session, $Request, $Response, $Server, $Application)

Called just after we have finished transferring the file to the client.  This would be a good
time to make a note that the download occurred (who downloaded what and when).

=head1 ADVANCED METHODS

The following are overridable methods that - if necessary - can be overridden to achieve specialized
functionality (such as composing file paths differently, for example).

=head2 compose_download_file_path($s, $Session, $Request, $Response, $Server, $Application)

=head2 compose_download_file_name($s, $Session, $Request, $Response, $Server, $Application)

=head2 compose_upload_file_name($s, $Session, $Request, $Response, $Server, $Application, $Upload)

=head2 delete_file($s, $Session, $Request, $Response, $Server, $Application, $filename)

=head2 open_file_for_writing($s, $Session, $Request, $Response, $Server, $Application, $filename)

=head2 send_http_headers($s, $Session, $Request, $Response, $Server, $Application, $filename, $file, $ext)

=head2 compose_upload_file_name($s, $Session, $Request, $Response, $Server, $Application, $Upload)

=head2 open_file_for_appending($s, $Session, $Request, $Response, $Server, $Application, $filename)

=head1 SEE ALSO

See L<Apache2::ASP::UploadHandler> for details about the C<$Upload> parameter passed to
the C<*_create> and C<*_update> methods.

=head1 AUTHOR

John Drago L<mailto:jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut
