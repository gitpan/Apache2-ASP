
package Apache2::ASP::ApacheRequest;

use strict;
use warnings 'all';
use CGI ();
use Cwd 'cwd';


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  foreach(qw/ r uri status filename /)
  {
    die "Required parameter '$_' was not provided"
      unless defined($args{$_});
  }# end foreach()
  
  return bless {
    buffer => '',
    rflush => 1,
    q      => CGI->new(),
    _headers_out => { },
    %args
  }, $class;
}# end new()


#==============================================================================
sub print
{
  my ($s, $str) = @_;
  no warnings 'uninitialized';
  $s->{buffer} .= $str;
}# end print()


#==============================================================================
sub buffer
{
  my $s = shift;
  return $s->{buffer};
}# end buffer()


#==============================================================================
sub lookup_uri
{
  my ($s, $path) = @_;
  
  return if $s->{disable_lookup_uri};
  
  my $here = cwd();
  return ref($s)->new(
    r         => $s->{r},
    status    => $s->{status},
    uri       => $s->{uri},
    filename  => $here . $path
  );
}# end lookup_uri()


#==============================================================================
sub headers_out
{
  my ($s, $arg) = @_;
  return $s->{_headers_out} unless $arg;
  $s->{_headers_out} = $arg;
}# end headers_out()


#==============================================================================
sub connection
{
  my ($s) = @_;
  
  return ref($s)->new(
    client_socket => ref($s)->new(
      close => 1,
      r         => $s->{r},
      status    => $s->{status},
      uri       => $s->{uri},
      filename  => $s->{filename},
    ),
    r         => $s->{r},
    status    => $s->{status},
    uri       => $s->{uri},
    filename  => $s->{filename},
  );
}# end connection()


#==============================================================================
sub AUTOLOAD
{
  my $s = shift;
  our $AUTOLOAD;
  my ($method) = $AUTOLOAD =~ m/::([^:]+)$/;
  
  # If we can't handle the request, try passing it on to our request:
  if( ! exists( $s->{$method} ) )
  {
    no warnings 'uninitialized';
    if( $s->{r}->can($method) )
    {
      return $s->{r}->$method( @_ );
    }
    elsif( $s->{q}->can($method) )
    {
      return $s->{q}->$method( @_ );
    }
    else
    {
      die "Unhandled method '$method'";
    }# end if()
  }# end if()
  
  # Are we in 'setter' or 'getter' mode?
  if( @_ )
  {
    # Setter:
    return $s->{$method} = shift;
  }
  else
  {
    # Getter:
    return $s->{$method};
  }# end if()
}# end AUTOLOAD()

sub DESTROY { }

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::ApacheRequest - HTTP request abstraction for Apache2::ASP

=head1 SYNOPSIS

  # For internal use only.
  # See tests for usage examples.

=head1 DESCRIPTION

To offer some level of abstraction between L<Apache2::ASP> and its host
environment, this class was created to proxy method calls (or short-circuit them).

=head1 METHODS

=head2 new( %args )

Returns a new object.

C<%args> should include the following:

=over 4

=item r

An L<Apache2::RequestRec> object.  In its place you B<could> use any blessed reference.

=item uri

Something like C</index.asp>.  The relative URI of the ASP script requested.

=item status

Something valid like C<200 OK> or C<302 Found>

=item filename

The absolute path to the file specified in C<uri>.

Something like C</usr/local/mysite/htdocs/index.asp>.

=back

=head2 rflush( )

Returns C<1> and does nothing else.

=head2 print( $str )

Adds C<$str> to the internal string buffer.

=head2 buffer( )

Returns the contents of the internal string buffer (as a string).

=head2 lookup_uri( $uri )

Returns the absolute path to the script currently being executed.

Mimics the following functionality:

  $r->lookup_uri->filename();

=head2 headers_out( [\%headers] )

Returns the existing headers_out hash, or replaces it with one provided.

=head2 connection( )

Mimics the following functionality:

  $r->connection->client_socket->close();

=head1 A NOTE ON METHOD PROXYING

All other methods are proxied first to the passed-in L<Apache2::RequestRec> object,
then (supposing it can't answer to the method call) to a L<CGI> object.

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
