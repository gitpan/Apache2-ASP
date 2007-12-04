
package Apache2::ASP::Request;

use strict;
use warnings;

#==============================================================================
sub new
{
  my ($class, $asp) = @_;
  
  my $s = bless {
    asp => $asp,
    q => $asp->{q},
    r => $asp->{r},
  }, $class;
  
  my $unescape = $s->{q}->can('unescape') ? sub{ $s->{q}->unescape( @_ ) } : sub{ $s->{q}->url_decode( @_ ) };
  
  {
    no warnings 'uninitialized';
    $s->{cookies} = {
      map { 
        my ($k,$v) = split /\=/, $_;
        chomp($k);
        ($k => $v . '' )
      } split /;/, $ENV{HTTP_COOKIE}
    };
  }
  
  while( my ($key,$data) = each( %{ $s->{cookies} } ) )
  {
    next unless $data =~ m/\%3D/i;
    $data = $unescape->( $data );
    my %info = map {
      my ($k,$v) = split /\=/, $_;
      chomp($k);
      ( $k => $v )
    } split /&/, $data;
    $s->{cookies}->{ $key } = \%info;
  }# end while()
  
  return $s;
}# end new()


#==============================================================================
sub Cookies
{
  my ($s, $name, $key ) = @_;
  
  return unless exists($s->{cookies}->{$name});
  if( defined($key) && ref($s->{cookies}->{$name}) )
  {
    return $s->{cookies}->{$name}->{$key};
  }
  else
  {
    return $s->{cookies}->{$name};
  }# end if()
}# end Cookies()


#==============================================================================
sub Form
{
  my $s = shift;
  if( @_ )
  {
    my $arg = shift;
    my $val = $s->{q}->param( $arg );
    if( defined($val) )
    {
      return $val;
    }
    else
    {
      if( my $last = $s->{asp}->session->{__lastArgs} )
      {
        if( my $page_args = $last )
        {
          return $page_args->{ $arg };
        }# end if()
      }# end if()
    }# end if()
  }
  else
  {
    no warnings 'uninitialized';
    my $page_args = { };
    if( my $last = $s->{asp}->session->{__lastArgs} )
    {
      $page_args = ref($last) ? $last : { };
    }# end if()
    
    my %info = ( %$page_args, map { $_ => $s->{q}->param( $_ ) } $s->{q}->param );
    return \%info;
  }# end if()
}# end Form()


#==============================================================================
sub FileUpload
{
  my ($s, $field, $arg) = @_;
  my $ifh = $s->{q}->upload($field);
  my %info = ();
  my $upInfo = { };
  
  if( $s->{q}->isa('CGI::Simple') )
  {
    no warnings 'uninitialized';
    %info = (
      ContentType           => $s->{q}->upload_info( $field, 'mime' ),
      FileHandle            => $ifh,
      BrowserFile           => $s->Form->{ $field } . "",
      'Content-Disposition' => 'attachment',
      'Mime-Header'         => $s->{q}->upload_info( $field, 'mime' ),
    );
  }
  else
  {
    $upInfo = $s->{q}->uploadInfo( $ifh );
    no warnings 'uninitialized';
    %info = (
      ContentType           => $upInfo->{'Content-Type'},
      FileHandle            => $ifh,
      BrowserFile           => $s->Form->{ $field } . "",
      'Content-Disposition' => $upInfo->{'Content-Disposition'},
      'Mime-Header'         => $upInfo->{type},
    );
  }# end if()
  
  if( $field )
  {
    if( wantarray )
    {
      return %info;
    }
    else
    {
      if( $arg )
      {
        return $info{ $arg };
      }
      else
      {
        return $ifh;
      }# end if()
    }# end if()
  }
  else
  {
    die "FileUpload() called without arguments";
  }# end if()
  
}# end FileUpload()


#==============================================================================
sub QueryString
{
  $ENV{HTTP_QUERYSTRING};
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
}# end ServerVariables()\


#==============================================================================
sub asp { $_[0]->{asp} }


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

=head2 new( $asp )

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

