
package Apache2::ASP::Parser;

use strict;
use warnings 'all';


#==============================================================================
sub parse_file
{
  my ($s, $file) = @_;
  
  no warnings 'uninitialized';
  open my $ifh, '<', $file
    or die "Cannot open file '$file': $!";
  local $/;
  my $txt = <$ifh>;
  close($ifh);
  return $s->parse_string( $txt );
}# end parse_file()


#==============================================================================
sub parse_string
{
  my ($s, $txt) = @_;
  
  $txt = '$Response->Write(q~' . $txt . '~);';
  $txt =~ s@
    <\%([^\=].*?)\%>
  @~);$1;\$Response->Write(q~@sgx;
  
  $txt =~ s@
    <%=(.*?)%>
  @~);\$Response->Write($1);\$Response->Write(q~@sgx;
  
  $txt =~ s@\$Response\-\>End(?:\(?[\s.]*?\)?);@return;@g;
  $txt =~ s@\$Response\-\>Redirect\(@return \$Response\->Redirect\(@g;
  
  $txt =~ s@\$Response\-\>Write\(q\~(.*?)\~\);@
    '$Response->Write(q~' . _fix_tilde($1) . '~);'
  @sxge;

  return $txt;
}# end parse_string()


#==============================================================================
sub _fix_tilde
{
  my $str = shift;
  $str =~ s/~/_____TILDE_____/g;
  return $str;
}# end _fix_tilde()

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::Parser - ASP -> Perl parsing engine

=head1 SYNOPSIS

  my $parsed_file = Apache2::ASP::Parser->parse_file( $asp_filename );
  
  my $parsed_str  = Apache2::ASP::Parser->parse_string( $asp_string );

=head1 DESCRIPTION

Converts ASP code like:

  <%
    $Response->Write("Hello, World!");
    $Response->End;
  %>

Into Perl code like:

  $Response->Write(q~~);
  $Response->Write("Hello, World!");
  return;
  ;$Response->Write(q~
  ~);

=head1 METHODS

=head2 parse_file( $path_to_file )

Returns the contents of that file, parsed into ASP Perl.

=head2 parse_string( $str )

Returns C<$str>, parsed into ASP Perl.

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

