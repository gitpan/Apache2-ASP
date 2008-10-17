
package Apache2::ASP::MediaManager;

use strict;
use base 'Apache2::ASP::UploadHandler';
use MIME::Types;

my $mimetypes = MIME::Types->new();


#==============================================================================
sub run
{
  my ($s, $context) = @_;
  
  shift(@_);
	
	my $mode = $context->request->Form->{mode};
	
	return unless ( ! $mode ) || ( $mode !~ m/^(create|edit)$/ );
	
  my $filename = $s->compose_download_file_path( $context );
  my $file = $s->compose_download_file_name( $context );
  
  # Find its MIME type and set our 'ContentType' value:
  my ($ext) = $file =~ m/.*?\.([^\.]+)$/;
  $ext ||= 'txt';
  my $type = $mimetypes->mimeTypeOf( $ext );
  $context->response->ContentType( $type );
  
  # Call our extension hooks:
  if( $mode )
  {
    if( $mode eq 'delete' )
    {
      -f $filename or return 404;
      $s->before_delete( $context, $filename )
        or return;
      $s->delete_file( $context, $filename );
      $s->after_delete( $context, $filename );
      return;
    }
    elsif( defined(my $handler = $s->modes( $mode )) )
    {
      return $handler->( @_ );
    }# end if()
  }# end if()
  
  # Get the readable filehandle:
  unless( -f $filename )
  {
    $context->response->Status( 404 );
    return;
  }# end unless()
  
  # Call our before- hook:
  $s->before_download( $context )
    or return;
  
  # Wait until "before_download" has cleared before we open a filehandle:
  my $ifh = $s->open_file_for_reading( $context, $filename );
  
  # Send any HTTP headers:
  $s->send_http_headers($context, $filename, $file, $ext);
  
  # Print the file out:
  while( my $line = <$ifh> )
  {
    $context->response->Write( $line );
#    $context->response->Flush;
  }# end while()
  $context->response->Flush;
  
  # Done!
  close($ifh);
  
  # Call our after- hook:
  $s->after_download( $context );
}# end run()


#==============================================================================
sub send_http_headers
{
  my ($s, $context, $filename, $file, $ext) = @_;
  
  # Send the 'content-length' header:
  $context->response->AddHeader( 'Content-Length' => -s $filename );
  
  # PDF files should force the "Save file as..." dialog:
  my $disposition = (lc($ext) eq 'pdf') ? 'attachment' : 'inline';
  $file =~ s/\s/_/g;
  $context->response->AddHeader( 'content-disposition' => "$disposition;filename=" . $file );
}# end send_http_headers()


#==============================================================================
sub delete_file
{
  my ($s, $context, $filename) = @_;
  
  die "'$filename' is a directory, not a file" if -d $filename;
  unlink( $filename )
    or die "Cannot delete file '$filename' from disk: $!";
}# end delete_file()


#==============================================================================
sub open_file_for_writing
{
  my ($s, $context, $filename) = @_;
  
  # Try to open the file for writing:
  open my $ifh, '>', $filename
    or die "Cannot open file '$filename' for writing: $!";
  binmode($ifh);
  
  return $ifh;
}# end open_file_for_writing()


#==============================================================================
sub open_file_for_reading
{
  my ($s, $context, $filename) = @_;
  
  # Try to open the file for reading:
  open my $ifh, '<', $filename
    or die "Cannot open file '$filename' for reading: $!";
  binmode($ifh);
  
  return $ifh;
}# end open_file_for_reading()


#==============================================================================
sub open_file_for_appending
{
  my ($s, $context, $filename) = @_;
  
  # Try to open the file for appending:
  open my $ifh, '>>', $filename
    or die "Cannot open file '$filename' for appending: $!";
  binmode($ifh);
  
  return $ifh;
}# end open_file_for_appending()


#==============================================================================
sub compose_download_file_path
{
  my ($s, $context) = @_;
  
  # Compose the local filename:
  my $file = $context->request->Form->{file};
  my $filename = $context->config->web->media_manager_upload_root . '/' . $file;
  
  return $filename;
}# end compose_file_path()


#==============================================================================
sub compose_download_file_name
{
  my ($s, $context) = @_;
  
  # Compose the local filename:
  my $file = $context->request->Form->{file};
  
  return $file;
}# end compose_file_name()


#==============================================================================
sub compose_upload_file_name
{
  my ($s, $context, $Upload) = @_;
  
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
  my ($s, $context, $Upload, $filename) = @_;
  
  unless( defined($filename) && length($filename) )
  {
    die "\$filename not provided";
  }# end unless()
  
  return $context->config->web->media_manager_upload_root . "/$filename";
}# end compose_upload_file_path()


#==============================================================================
sub upload_start
{
  my ($s, $context, $Upload) = @_;
  
  shift(@_);
  $s->SUPER::upload_start( @_ );
  
  my $filename = $s->compose_upload_file_name( @_ );
  
  # Depending on the 'mode' parameter, we do different things:
  local $_ = $context->request->Form->{mode};
  if( /^create$/ )
  {
    $s->before_create($context, $Upload)
      or return;
  }
  elsif( /^edit$/ )
  {
    $s->before_update($context, $Upload)
      or return;
  }
  else
  {
    die "Unknown mode: '$_'";
  }# end if()
  
  # Make sure we can open the file for writing:
  my $target_file = $s->compose_upload_file_path( $context, $Upload, $filename);
  
  # Open the file for writing:
  my $ofh = $s->open_file_for_writing($context, $target_file);
  
  # Done with the filehandle:
  close($ofh);
  
  # Store some information for later:
  $context->r->pnotes( filename => $target_file );
  $context->r->pnotes( download_file => $filename );
}# end upload_start()


#==============================================================================
sub upload_hook
{
  my ($s, $context, $Upload) = @_;
  
  shift(@_);
  $s->SUPER::upload_hook( @_ );
  
  my $filename = $context->r->pnotes( 'filename' )
    or die "Couldn't get pnotes 'filename'";
  
  my $ofh = $s->open_file_for_appending($context, $filename);
  no warnings 'uninitialized';
  print $ofh $Upload->{data};
  close($ofh);
}# end upload_hook()


#==============================================================================
sub upload_end
{
  my ($s, $context, $Upload) = @_;
  
  shift(@_);
  $s->SUPER::upload_end( @_ );
  
  # Return information about what we just did:
  my $info = {
    new_file      => $context->r->pnotes( 'filename' ),
    filename_only => $context->r->pnotes( 'download_file' ),
    link_to_file  => "/media/" . $context->r->pnotes( 'download_file' ),
  };
  $Upload->{$_} = $info->{$_} foreach keys(%$info);
  
  # Depending on the 'mode' parameter, we do different things:
  local $_ = $context->request->Form->{mode};
  if( /^create$/ )
  {
    $s->after_create($context, $Upload);
  }
  elsif( /^edit$/ )
  {
    $s->after_update($context, $Upload);
  }
  else
  {
    die "Unknown mode: '$_'";
  }# end if()
}# end upload_end()


#==============================================================================
sub before_download
{
  my ($s, $context) = @_;
  
}# end before_download()


#==============================================================================
sub after_download
{
  my ($s, $context) = @_;
  
}# end after_download()


#==============================================================================
sub before_create
{
  my ($s, $context, $Upload) = @_;
  
}# end before_create()


#==============================================================================
sub before_update
{
  my ($s, $context, $Upload) = @_;
  
}# end before_update()


#==============================================================================
sub after_create
{
  my ($s, $context, $Upload) = @_;
  
}# end after_create()


#==============================================================================
sub after_update
{
  my ($s, $context, $Upload) = @_;
  
}# end after_update()


#==============================================================================
sub before_delete
{
  my ($s, $context, $filename) = @_;
  
}# end before_delete()


#==============================================================================
sub after_delete
{
  my ($s, $context, $filename) = @_;
  
}# end after_delete()

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::MediaManager - Instant file management for Apache2::ASP applications

=head1 SYNOPSIS

TDB

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
