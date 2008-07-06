
package Apache2::ASP::MediaManager;

use strict;
use base 'Apache2::ASP::UploadHandler';
use MIME::Types;

my $mimetypes = MIME::Types->new();
our %modes = ();


#==============================================================================
sub run
{
  my ($s, $asp) = @_;
  
  shift(@_);
	
	my $mode = $asp->request->Form('mode');
	
	return unless ( ! $mode ) || ( $mode !~ m/^(create|edit)$/ );
	
  my $filename = $s->compose_download_file_path( $asp );
  my $file = $s->compose_download_file_name( $asp );
  
  # Find its MIME type and set our 'ContentType' value:
  my ($ext) = $file =~ m/.*?\.([^\.]+)$/;
  $ext ||= 'txt';
  my $type = $mimetypes->mimeTypeOf( $ext );
  $asp->response->{ContentType} = $type;
  
  # Call our extension hooks:
  if( $mode )
  {
    if( $mode eq 'delete' )
    {
      -f $filename or return 404;
      $s->before_delete( $asp, $filename )
        or return;
      $s->delete_file( $asp, $filename );
      $s->after_delete( $asp, $filename );
      return;
    }
    elsif( defined($modes{ $mode }) )
    {
      return $modes{$mode}->( @_ );
    }# end if()
  }# end if()
  
  # Get the readable filehandle:
  unless( -f $filename )
  {
    $asp->response->{Status} = 404;
    return;
  }# end unless()
  
  # Call our before- hook:
  $s->before_download( $asp )
    or return;
  
  # Wait until "before_download" has cleared before we open a filehandle:
  my $ifh = $s->open_file_for_reading( $asp, $filename );
  
  # Send any HTTP headers:
  $s->send_http_headers($asp, $filename, $file, $ext);
  
  # Print the file out:
  while( my $line = <$ifh> )
  {
    $asp->response->Write( $line );
    $asp->response->Flush;
  }# end while()
  
  # Done!
  close($ifh);
  
  # Call our after- hook:
  $s->after_download( $asp );
}# end run()


#==============================================================================
sub send_http_headers
{
  my ($s, $asp, $filename, $file, $ext) = @_;
  
  # Send the 'content-length' header:
  $asp->response->AddHeader( 'Content-Length' => -s $filename );
  
  # PDF files should force the "Save file as..." dialog:
  my $disposition = (lc($ext) eq 'pdf') ? 'attachment' : 'inline';
  $file =~ s/\s/_/g;
  $asp->response->AddHeader( 'content-disposition' => "$disposition;filename=" . $file );
}# end send_http_headers()


#==============================================================================
sub delete_file
{
  my ($s, $asp, $filename) = @_;
  
  unlink( $filename )
    or die "Cannot delete file '$filename' from disk: $!";
}# end delete_file()


#==============================================================================
sub open_file_for_writing
{
  my ($s, $asp, $filename) = @_;
  
  # Try to open the file for writing:
  open my $ifh, '>', $filename
    or die "Cannot open file '$filename' for writing: $!";
  binmode($ifh);
  
  return $ifh;
}# end open_file_for_writing()


#==============================================================================
sub open_file_for_reading
{
  my ($s, $asp, $filename) = @_;
  
  # Try to open the file for reading:
  open my $ifh, '<', $filename
    or die "Cannot open file '$filename' for reading: $!";
  binmode($ifh);
  
  return $ifh;
}# end open_file_for_reading()


#==============================================================================
sub open_file_for_appending
{
  my ($s, $asp, $filename) = @_;
  
  # Try to open the file for appending:
  open my $ifh, '>>', $filename
    or die "Cannot open file '$filename' for appending: $!";
  binmode($ifh);
  
  return $ifh;
}# end open_file_for_appending()


#==============================================================================
sub compose_download_file_path
{
  my ($s, $asp) = @_;
  
  # Compose the local filename:
  my $file = $asp->request->Form->{file};
  my $filename = $asp->config->media_manager_upload_root . '/' . $file;
  
  return $filename;
}# end compose_file_path()


#==============================================================================
sub compose_download_file_name
{
  my ($s, $asp) = @_;
  
  # Compose the local filename:
  my $file = $asp->request->Form->{file};
  
  return $file;
}# end compose_file_name()


#==============================================================================
sub compose_upload_file_name
{
  my ($s, $asp, $Upload) = @_;
  
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
  my ($s, $asp, $Upload, $filename) = @_;
  
  return $asp->config->media_manager_upload_root . "/$filename";
}# end compose_upload_file_path()


#==============================================================================
sub upload_start
{
  my ($s, $asp, $Upload) = @_;
  
  shift(@_);
  $s->SUPER::upload_start( @_ );
  
  my $filename = $s->compose_upload_file_name( @_ );
  
  # Depending on the 'mode' parameter, we do different things:
  local $_ = $asp->request->Form('mode');
  if( /^create$/ )
  {
    $s->before_create($asp, $Upload)
      or return;
  }
  elsif( /^edit$/ )
  {
    $s->before_update($asp, $Upload)
      or return;
  }
  else
  {
    die "Unknown mode: '$_'";
  }# end if()
  
  # Make sure we can open the file for writing:
  my $target_file = $s->compose_upload_file_path( $asp, $Upload, $filename);
  
  # Open the file for writing:
  my $ofh = $s->open_file_for_writing($asp, $target_file);
  
  # Done with the filehandle:
  close($ofh);
  
  # Store some information for later:
  $asp->server->{r}->pnotes( filename => $target_file );
  $asp->server->{r}->pnotes( download_file => $filename );
}# end upload_start()


#==============================================================================
sub upload_hook
{
  my ($s, $asp, $Upload) = @_;
  
  shift(@_);
  $s->SUPER::upload_hook( @_ );
  
  my $filename = $asp->server->{r}->pnotes( 'filename' )
    or die "Couldn't get pnotes 'filename'";
  
  my $ofh = $s->open_file_for_appending($asp, $filename);
  no warnings 'uninitialized';
  print $ofh $Upload->{data};
  close($ofh);
}# end upload_hook()


#==============================================================================
sub upload_end
{
  my ($s, $asp, $Upload) = @_;
  
  shift(@_);
  $s->SUPER::upload_end( @_ );
  
  # Return information about what we just did:
  my $info = {
    new_file      => $asp->server->{r}->pnotes( 'filename' ),
    filename_only => $asp->server->{r}->pnotes( 'download_file' ),
    link_to_file  => "/media/" . $asp->server->{r}->pnotes( 'download_file' ),
  };
  $Upload->{$_} = $info->{$_} foreach keys(%$info);
  
  # Depending on the 'mode' parameter, we do different things:
  local $_ = $asp->request->Form('mode');
  if( /^create$/ )
  {
    $s->after_create($asp, $Upload);
  }
  elsif( /^edit$/ )
  {
    $s->after_update($asp, $Upload);
  }
  else
  {
    die "Unknown mode: '$_'";
  }# end if()
}# end upload_end()


#==============================================================================
sub before_download
{
  my ($s, $asp) = @_;
  
}# end before_download()


#==============================================================================
sub after_download
{
  my ($s, $asp) = @_;
  
}# end after_download()


#==============================================================================
sub before_create
{
  my ($s, $asp, $Upload) = @_;
  
}# end before_create()


#==============================================================================
sub before_update
{
  my ($s, $asp, $Upload) = @_;
  
}# end before_update()


#==============================================================================
sub after_create
{
  my ($s, $asp, $Upload) = @_;
  
}# end after_create()


#==============================================================================
sub after_update
{
  my ($s, $asp, $Upload) = @_;
  
}# end after_update()


#==============================================================================
sub before_delete
{
  my ($s, $asp, $filename) = @_;
  
}# end before_delete()


#==============================================================================
sub after_delete
{
  my ($s, $asp, $filename) = @_;
  
}# end after_delete()


#==============================================================================
sub register_mode
{
  my ($s, %info) = @_;
  
  $modes{ $info{name} } = $info{handler};
}# end register_mode()

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::MediaManager - Instant file management for Apache2::ASP applications

=head1 SYNOPSIS

First, add the following to your httpd.conf file:

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
    my ($s, $asp, $Upload) = @_;
    
    my $user = my_user_finding_method();
    if( ! ( $user && $user->can_upload_files() ) )
    {
      return 1;
    }
    else
    {
      $asp->session->{message} = "You are not authorized to upload files";
      $asp->response->Redirect("/unauthorized.asp");
      return 0;
    }# end if()
  }# end before_create()
  
  #==============================================================================
  # Redirect the user to a "thank you" page:
  sub after_create
  {
    my ($s, $asp, $Upload) = @_;
    
    # Do whatever we want to the new file on disk:
    # recombobulate( $Upload->new_file );
    
    # Store a friendly message:
    $asp->session->{message} = "Your upload was successful";
    
    # Redirect the user to your "Thank you" page:
    $asp->response->Redirect( "/upload_completed.asp" );
  }# end after_create()
  
  1;# return true:

Now, when you want to upload files, just point the upload form to
/handlers/MyMediaManager, like so:

  <html>
  ...
  <form method="POST" enctype="multipart/form-data" action="/handlers/MyMediaManager">
    <!-- This "mode" parameter tells us what we're going to do -->
    <!-- Possible values include "create", "update" and "delete" -->
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

=head1 PROTECTED METHODS

The following methods are intended for subclasses of C<Apache2::ASP::MediaManager>.

=head2 register_mode( %args )

Allows your MediaManager class to handle "mode=xxx" requests on files.

Example:

  package MyMediaManager;
  
  use base 'Apache2::ASP::MediaManager';
  
  __PACKAGE__->register_mode(
    name    => 'mymode',
    handler => \&do_mymode,
  );
  
  # Accessible via URLs such as /media/[filename]?mode=mymode
  sub do_mymode
  {
    # ... do stuff ...
    $Response->Write("mymode is successful!");
  }# end do_mymode()

Any call to C</media/file123.gif?mode=mymode> will execute your C<do_mymode()> method.

This is useful for generating image thumbnails - i.e. C</media/file123.gif?mode=thumb&max_w=100&max_h=80>

The rest is left as an exercise for the reader.

=head1 OVERRIDABLE METHODS

=head2 before_create($s, $asp, $Upload)

Called just before we begin reading data from the client.  This would be a good time to verify
that the user is allowed to upload files.

=head2 after_create($s, $asp, $Upload)

Called just after we have finished writing data to the new file.  This would be a good 
time to do any post-processing on the file (i.e. store metadata about the upload in a 
database).

=head2 before_update($s, $asp, $Upload)

Called just before we begin reading data from the client.  This would be a good time to verify
that the user is allowed to update this file.

=head2 after_update($s, $asp, $Upload)

Called just after we have finished writing data to the existing file.  This would be a good 
time to do any post-processing on the file (i.e. store metadata about the upload in a 
database, delete any cached thumbnails, etc.).

=head2 before_delete($s, $asp, $filename)

Called just before we delete the file from disk.  This would be a good time to verify
that the user is allowed to delete this file.

=head2 after_delete($s, $asp, $filename)

Called just after we delete the file from disk.  This would be a good time to do any
post-processing (i.e. delete any metadata about the file in a database, delete any cached 
thumbnails, etc.)

=head2 before_download($s, $asp)

Called just after we have verified that the file exists and that we can open it for reading,
but before we have printed any data to the client.  This would be a good time to verify that
the user is allowed to download this file.

=head2 after_download($s, $asp)

Called just after we have finished transferring the file to the client.  This would be a good
time to make a note that the download occurred (who downloaded what and when).

=head1 ADVANCED METHODS

The following are overridable methods that - if necessary - can be overridden to achieve specialized
functionality (such as composing file paths differently, or archiving files instead of deleting them,
for example).

=head2 compose_download_file_path($s, $asp)

Should return a string like "file_to_be_downloaded.gif"

=head2 compose_download_file_name($s, $asp)

Should return a string like "/absolute/local/path/to/file.gif"

=head2 delete_file($s, $asp, $filename)

Should delete C<$filename> from disk.

=head2 send_http_headers($s, $asp, $filename, $file, $ext)

Should cause any HTTP headers to be sent to the client.

=head2 compose_upload_file_name($s, $asp, $Upload)

Should return a string like "uploaded_file.gif"

=head2 open_file_for_reading($s, $asp, $filename)

Should return a filehandle opened for reading.

=head2 open_file_for_writing($s, $asp, $filename)

Should return a filehandle opened for writing.

=head2 open_file_for_appending($s, $asp, $filename)

Should return a filehandle opened for appending.

=head1 SEE ALSO

See L<Apache2::ASP::UploadHandler> for details about the C<$Upload> parameter passed to
the C<*_create> and C<*_update> methods.

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
