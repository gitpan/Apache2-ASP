
package Apache2::ASP::Parser;

use strict;
use warnings 'all';


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
