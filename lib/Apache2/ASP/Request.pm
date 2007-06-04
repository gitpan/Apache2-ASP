
package Apache2::ASP::Request;

use strict;
use warnings;

#==============================================================================
sub new
{
  my ($s, $r, $q) = @_;
  
  return bless {
    q => $q,
    r => $r,
  }, ref($s) || $s;
}# end new()


#==============================================================================
sub Cookies
{
  my ($s, $name, $key ) = @_;
  
  my $cookie = $s->{q}->cookie( $name );
  
  no warnings 'uninitialized';
  return $cookie unless defined($key);
  
  $cookie = $s->{q}->unescape( $cookie );
  my %info = map {
    my ($k,$v) = split /\=/, $_;
    $k => $v;
  } split( /&/, $cookie );
  
  return $info{$key};
}# end Cookies()


#==============================================================================
sub Form
{
  my $s = shift;
  if( @_ )
  {
    my $arg = shift;
    my $val = $s->{q}->param( $arg );
    return defined($val) ? $val : '';
  }
  else
  {
    my %info = map { $_ => $s->{q}->param( $_ ) } $s->{q}->param;
    return \%info;
  }# end if()
}# end Form()


#==============================================================================
sub FileUpload
{
  my ($s, $field, $arg) = @_;
  
  my $ifh = $s->{q}->upload($field);
  my $upInfo = $s->{q}->uploadInfo( $ifh );
  my %info = (
    ContentType           => $upInfo->{'Content-Type'},
    FileHandle            => $ifh,
    BrowserFile           => $s->Form->{ $field } . "",
    'Content-Disposition' => $upInfo->{'Content-Disposition'},
    'Mime-Header'         => $upInfo->{type},
  );
  
  if( $field && wantarray )
  {
    return $info{ $arg };
  }
  elsif( $field && ( ! wantarray ) )
  {
    return $ifh;
  }
  else
  {
    die "FileUpload() called without arguments";
  }# end if()
}# end FileUpload()


#==============================================================================
sub QueryString
{
  defined($ENV{HTTP_QUERYSTRING}) ? $ENV{HTTP_QUERYSTRING} : "";
}# end Form()


#==============================================================================
sub ServerVariables
{
  my $s = shift;
  
  if( @_ )
  {
    return $ENV{$_[0]};
  }
  else
  {
    return sort keys %ENV;
  }# end if()
}# end ServerVariables()


#==============================================================================
sub DESTROY
{
}# end DESTROY()

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::Request - Incoming request processor

=head1 SYNOPSIS

  <%
    # Cookies:
    my $cookie = $Request->Cookies( "mycookie" );
    my $cookie2 = $Request->Cookies( "cookie2", "fieldname" );
    
    # Form/QueryString values:
    my $Form = $Request->Form; # returns a hashref of all form/querystring data:
    my $name = $Form->{user_name};
    my $name = $Request->Form( 'user_name' );
    
    # File uploads (a):
    my $ifh = $Request->FileUpload( "fieldname" );
    while( my $line = <$ifh> )
    {
      # Process $line from file:
    }# end while()
    
    # File uploads (b):
    my %info = $Request->FileUpload( "fieldname" );
    # %info has the following structure:
    %info = (
      'ContentType'         => 'image/gif',
      'FileHandle'          => <an IO::Handle object>,
      'BrowserFile'         => 'C:\Documents and Settings\franky\Desktop\myfile.gif'
    );
    
    # QueryString itself:
    my $qstring = $Request->QueryString();
    
    # ServerVariables:
    my $host = $Request->ServerVariables( 'HTTP_HOST' );
  %>

=head1 DESCRIPTION

The global C<$Request> object is an instance of C<Apache2::ASP::Request>.

=head1 PUBLIC METHODS

=head2 Cookies( $name [, $key] )

Given the C<$name> only, returns the whole value of the cookie.

Given the C<$name> and C<$key>, returns only that part of a multi-value cookie.

=head2 Form( [$key] )

Called without a C<$key>, returns a hashref of all Form and QueryString data.

Called with a C<$key>, returns only the value for that field.

=head2 FileUpload( $field [, $arg ] )

Called in scalar context, returns a filehandle to the uploaded file.

Called in list context, returns a hash containing the following fields:

=over 4

=item * ContentType

A value like C<image/gif> or C<text/html>.  The MIME-Type of the uploaded file.

=item * FileHandle

The stream/filehandle from which the contents of the uploaded file may be read.

=item * BrowserFile

The name of the file as it was on the client's side.  For example, C<C:\Program Files\file.txt>.

=back

=head2 QueryString( )

Returns the contents of C<$ENV{HTTP_QUERYSTRING}> or an empty string if it is not available.

=head2 ServerVariables( [$key] )

Called without a C<$key>, returns a sorted list of all keys in C<%ENV>.

Called with a C<$key>, returns the value associated with that element in C<%ENV>.

=head1 AUTHOR

John Drago L<jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut
