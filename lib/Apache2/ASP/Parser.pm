
package Apache2::ASP::Parser;

use strict;
use warnings 'all';

our $VERSION = 0.01;


#==============================================================================
sub parse_file
{
  my ($s, $file) = @_;
  
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
  @~);$1\$Response->Write(q~@sgx;
  
  $txt =~ s@
    <%=(.*?)%>
  @~);\$Response->Write($1);\$Response->Write(q~@sgx;
  
  $txt =~ s@\$Response\-\>End(?:\(?[\s.]*?\)?);@return;@g;
  
  return $txt;
}# end parse_string()

1;# return true:
