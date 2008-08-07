
package Apache2::ASP::Parser;

use strict;
use warnings 'all';
use Carp 'confess';
use Data::Dumper;


#==============================================================================
sub parse_file
{
  my ($s, $file) = @_;
  
  no warnings 'uninitialized';
  open my $ifh, '<', $file
    or confess "Cannot open file '$file': $!";
  local $/;
  my $txt = <$ifh>;
  close($ifh);
  return $s->parse_string( $txt );
}# end parse_file()


#==============================================================================
sub parse_string
{
  my ($class, $txt) = @_;
  
  # Look for <My:Tag>...</My:Tag> elements:
  while(
    $txt =~ m@
      (<(([a-z]+?[a-z0-9_]*\:[a-z0-9_\:]+)\s*(.*?))>(.*?)</\3\s*>)
    @xi #@ Make Gedit Happy
  ) {
    my $tagname = $3;
    my $argstr = $4;
    my $fulltag = $1;
    my $innerHTML = $5;
    $class->_render_tag(
      \$txt, $tagname, $argstr, $fulltag, $innerHTML
    );
  }# end while()
  
  # Look for <My:Tag /> elements:
  while(
    $txt =~ m@
      (<(([a-z]+?[a-z0-9_]*\:[a-z0-9_\:]+)\s*(.*?))/>)
    @xi #@ Make Gedit Happy
  )
  {
    my $tagname = $3;
    my $argstr = $4;
    my $fulltag = $1;
    $class->_render_tag(
      \$txt, $tagname, $argstr, $fulltag
    );
  }# end while()
  
  $txt = $class->_parse_include_tags( $txt );
  
  $txt = $class->_parse_asp_tags( $txt );
}# end parse_string()


#==============================================================================
sub _parse_include_tags
{
  my ($class, $txt) = @_;
  
  while( $txt =~ m@(<\!\-\-\s+\#include\s+(.*?)\s+\-\->)@si ) #@ Make GEdit Happy
  {
    my $wholetag = $1;
    my $include = $2;
    my $replacement = '';
    
    if( $include =~ m/^virtual\=\"(.*?)\"/ )
    {
      $replacement = qq/<% \$Response->Include( \$Server->MapPath("$1") ); %>/;
    }
    elsif( $include =~ m/^file\=\"(.*?)\"/ )
    {
      $replacement = qq/<% \$Response->Include( "$1" ); %>/;
    }
    else
    {
      confess "Invalid include directive '$wholetag'";
    }# end if()
    
    $txt =~ s/\Q$wholetag\E/$replacement/;
  }# end while()
  
  return $txt;
}# end _parse_include_tags()


#==============================================================================
sub _render_tag
{
  my ($class, $aspstr, $tagname, $argstr, $fulltag, $innerHTML) = @_;
  
  no strict 'refs';
  (my $pkg = $tagname) =~ s/:/::/g;
  (my $pkgfile = "$pkg.pm") =~ s/::/\//g;
  eval { require $pkgfile } unless @{"$pkg\::ISA"};
  no warnings 'uninitialized';
  $innerHTML =~ s/\~/\\~/g;
  if( @{"$pkg\::ISA"} )
  {
    (my $args = Dumper($class->_parse_tag_args( $argstr ))) =~ s/^\$VAR1\s+\=\s+//;
    $args =~ s/;$//;
    $$aspstr =~ s@
      \Q$fulltag\E
    @~);__PACKAGE__->_load_tag_class('$pkg');\$Response->Write($pkg\->new->render( $args, q~$innerHTML~ ));\$Response->Write(q~@xi; #@ Make Gedit Happy
  }
  elsif( defined *{"$pkg"} )
  {
    my @parts = split /::/, $pkg;
    pop(@parts);
    my $pkg_class = join '::', @parts;
    (my $args = Dumper($class->_parse_tag_args( $argstr ))) =~ s/^\$VAR1\s+\=\s+//;
    $args =~ s/;$//;
    $$aspstr =~ s@
      \Q$fulltag\E
    @~);__PACKAGE__->_load_tag_class('$pkg_class');\$Response->Write(\&$pkg( $args, q~$innerHTML~ ));\$Response->Write(q~@xi; #@ Make Gedit Happy
  }
  else
  {
    confess "Cannot load tag '$tagname': $@";
  }# end if()
}# end _render_tag()


#==============================================================================
sub _parse_tag_args
{
  my ($s, $str) = @_;
  
  my $attr = { };
  while( $str =~ m@([^\s\=\"\']+)(\s*=\s*(?:(")(.*?)"|(')(.*?)'|([^'"\s=]+)['"]*))?@sg ) #@
  {
    my $key = $1;
    my $test = $2;
    my $val  = ( $3 ? $4 : ( $5 ? $6 : $7 ));
    my $lckey = lc($key);
    if( $test )
    {
      $key =~ tr/A-Z/a-z/;
      $attr->{$lckey} = $val;
    }
    else
    {
      $attr->{$lckey} = $key;
    }# end if()
  }# end while()
  
  return $attr;
}# end _parse_tag_args()


#==============================================================================
sub _parse_asp_tags
{
  my ($class, $txt) = @_;
  
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
}# end _parse_asp_tags()


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

