
package Apache2::ASP::Server;

use strict;
use warnings;
use Mail::Sendmail;


#==============================================================================
sub new
{
  my ($s, $asp) = @_;
  return bless {
    asp       => $asp,
    r         => $asp->{r},
    q         => $asp->{q},
    
    # This may be deprecated soon:
    ScriptRef => \"",
  }, $s;
}# end new()


#==============================================================================
# Shamelessly ripped off from Apache::ASP::Server, by Joshua Chamas,
# who shamelessly ripped it off from CGI.pm, by Lincoln D. Stein.
# :)
sub URLEncode
{
  my $toencode = $_[1];
  no warnings 'uninitialized';
  $toencode =~ s/([^a-zA-Z0-9_\-.])/uc sprintf("%%%02x",ord($1))/esg;
  $toencode;
}# end URLEncode()


#==============================================================================
sub HTMLEncode
{
  my ($s, $str) = @_;
  no warnings 'uninitialized';
  $str =~ s/&/&amp;/g;
  $str =~ s/</&lt;/g;
  $str =~ s/>/&gt;/g;
  $str =~ s/"/&quot;/g;
  $str =~ s/'/&#39;/g;
  return $str;
}# end HTMLEncode()


#==============================================================================
sub HTMLDecode
{
  my ($s, $str) = @_;
  no warnings 'uninitialized';
  $str =~ s/&lt;/</g;
  $str =~ s/&gt;/>/g;
  $str =~ s/&quot;/"/g;
  $str =~ s/&amp;/&/g;
  return $str;
}# end HTMLEncode()


#==============================================================================
sub MapPath
{
  my ($s, $path) = @_;
  
  return unless defined($path);
  
  my $subr = $s->{r}->lookup_uri( $path );
  my $file = $subr ? $subr->filename : undef;
  return unless defined($file);
  if( -f $file )
  {
    return $file;
  }
  else
  {
    my $file = $s->{asp}->config->www_root . $path;
    return -f $file ? $file : undef;
  }# end if()
}# end MapPath()


#==============================================================================
sub Mail
{
  my ($s, %args) = @_;
  
  Mail::Sendmail::sendmail( %args );
}# end Mail()


#==============================================================================
sub RegisterCleanup
{
  my ($s, $sub) = @_;
  
  $s->{r}->pool->cleanup_register( $sub );
}# end RegisterCleanup()


#==============================================================================
sub DESTROY
{
  
}# end DESTROY()

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::Server - Utility object for Apache2::ASP programming

=head1 DESCRIPTION

The global C<$Server> object is used in ASP programming for utility tasks such as
string sanitation, finding files, sending email and registering subroutines to be
performed asynchronously.

=head1 EXAMPLES

=head1 PUBLIC METHODS

=head2 new( $asp )

=head2 URLEncode( $str )

Returns a URL-Encoded version of the string provided.

For example, "test@test.com" becomes "test%40test.com" with C<URLEncode()>.

=head2 HTMLEncode( $str )

Returns an HTML-Encoded version of the string provided.

For example, "<b>Hello</b>" becomes "C<&lt;b&gt;Hello&lt;/b&gt;>" with C<HTMLEncode()>.

=head2 HTMLDecode( $str )

Returns an HTML-Decoded version of the string provided.

For example, "C<&lt;b&gt;Hello&lt;/b&gt;>" becomes "<b>Hello</b>" with C<HTMLDecode()>.

=head2 MapPath( $path )

Given a relative path C<MapPath()> returns the absolute path to the file on disk.

For example, C<'/index.asp'> might return C<'/usr/local/dstack/www/index.asp'>.

=head2 Mail( %args )

A wrapper around the C<sendmail()> function from L<Mail::Sendmail>.

=head2 RegisterCleanup( $sub )

A wrapper around the function C<cleanup_register( $sub )> function provided by mod_perl2.

Pass in a subref that should be executed after the current request has completed.

For example:

  <%
    $Server->RegisterCleanup(sub { do_something_later() });
    # Do more stuff here:
    $Response->Write("Hello!");
  %>

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
