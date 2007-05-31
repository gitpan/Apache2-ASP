
package Apache2::ASP::MediaManager;

use strict;
use base 'Apache2::ASP::UploadHandler';
use MIME::Types;

my $mimetypes = MIME::Types->new();

#==============================================================================
sub run
{
  my ($s, $Session, $Request, $Response, $Server, $Application) = @_;
  
  my $filename = $ENV{APACHE2_MEDIA_MANAGER_UPLOAD_ROOT} . '/' . $Request->Form->{file};
  my ($ext) = $filename =~ m/.*?\.([^\.]+)$/;
  $ext ||= 'txt';
  my $type = $mimetypes->mimeTypeOf( $ext );
  $Response->{ContentType} = $type;
  
  open my $ifh, '<', $filename
    or die "Cannot open file '$filename': $!";
  binmode($ifh);

  $Response->AddHeader( 'Content-Length' => -s $filename );
  
  # PDF files should force the "Save file as..." dialog:
  my $disposition = (lc($ext) eq 'pdf') ? 'attachment' : 'inline';
  $Response->AddHeader( 'content-disposition' => "$disposition;filename=" . $Request->Form->{file} );
  
  # Print the file out:
  while( my $line = <$ifh> )
  {
    $Response->Write( $line );
    $Response->Flush;
  }# end while()
  
  # Done!
  close($ifh);
}# end run()

#==============================================================================
sub upload_start
{
  my ($s, $Session, $Request, $Response, $Server, $Application, $Upload) = @_;
  shift(@_);
  $s->SUPER::upload_start( @_ );
  
  my ($filename) = $Upload->{upload}->upload_filename =~ m/.*[\\\/]([^\/\\]+)$/;
  if( ! $filename )
  {
    $filename = $Upload->{upload}->upload_filename;
  }# end if()
  
  my $target_file = "$ENV{APACHE2_MEDIA_MANAGER_UPLOAD_ROOT}/$filename";
  open my $ofh, '>', $target_file
    or die "Cannot open '$target_file' for writing: $!";
  close($ofh);
  $Server->{r}->pnotes( filename => $target_file );
  $Server->{r}->pnotes( download_file => $filename );
}# end upload_start()


#==============================================================================
sub upload_hook
{
  my ($s, $Session, $Request, $Response, $Server, $Application, $Upload) = @_;
  shift(@_);
  $s->SUPER::upload_hook( @_ );
  
  my $filename = $Server->{r}->pnotes( 'filename' );
  
  open my $ofh, '>>', "$filename"
    or die "Cannot open '$filename' for appending: $!";
  my $ifh = $Upload->{upload}->upload_fh;
  binmode($ofh);
  print $ofh $Upload->{data};
  close($ofh);
}# end upload_hook()


#==============================================================================
sub upload_end
{
  my ($s, $Session, $Request, $Response, $Server, $Application, $Upload) = @_;
  shift(@_);
  $s->SUPER::upload_end( @_ );
  
  my $filename = $Server->{r}->pnotes( 'filename' );
  
  open my $ofh, '>>', "$filename"
    or die "Cannot open '$filename' for appending: $!";
  binmode($ofh);
  print $ofh $Upload->{data};
  close($ofh);
  
  # Return information about what we just did:
  return {
    new_file => $Server->{r}->pnotes( 'filename' ),
    filename_only => $Server->{r}->pnotes( 'download_file' ),
    link_to_file  => "/media/" . $Server->{r}->pnotes( 'filename' ),
  };
}# end upload_end()

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
  sub upload_end
  {
    my ($s, $Session, $Request, $Response, $Server, $Application, $Upload) = @_;
    shift(@_);
    my $info = $s->SUPER::upload_end( @_ );
    
    # Do whatever we want to the new file on disk:
    # recombobulate( $info->{new_file} );
    
    # Store a friendly message:
    $Session->{message} = "Your upload was successful";
    
    # Redirect the user to your "Thank you" page:
    $Response->Redirect( "/upload_completed.asp?file=$info->{link_to_file}" );
  }# end upload_end()
  
  1;# return true:

Now, when you want to upload files, just point the upload form to
/handlers/MyMediaManager, like so:

  <html>
  ...
  <form method="POST" enctype="multipart/form-data" action="/handlers/MyMediaManager">
    <input type="file" name="filename">
    <input type="submit" value="Click Here to Upload">
  </form>
  ...
  </html>

=head1 DESCRIPTION

Almost any web applications will eventually require some kind of file-upload functionality.

Apache2::ASP aims to deliver this right out of the box.  Since all the file-upload work is
already done, all you need to do is subclass C<Apache2::ASP::MediaManager> and go from there
(as shown in the synopsis above).

=head1 AUTHOR

John Drago L<mailto:jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut
