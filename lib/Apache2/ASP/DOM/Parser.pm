
package Apache2::ASP::DOM::Parser;

use strict;
use warnings 'all';
use Apache2::ASP::DOM::Document;
use Apache2::ASP::DOM::Node;
use Scalar::Util 'weaken';


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  my $s = bless \%args, $class;
  return $s;
}# end new()


#==============================================================================
sub parse
{
  my ($s, $txt) = @_;
  
  my $doc = Apache2::ASP::DOM::Document->new();
  $doc->{documentElement} = Apache2::ASP::DOM::Node->new(
    innerHTML   => $txt,
    parentNode  => $doc,
  );
  $doc->appendChild( $doc->documentElement );
  
  my @parents = ( $doc->documentElement );
  TAG: while( $txt =~ m@
      (</?(([a-z_0-9\:]+)\s*(.*?))/?>)
    @xi #@
  )
  {
    my $tagname = $3;
    my $argstr = $4;
    my $fulltag = $1;
    my $attrs = $s->_parse_tag_attrs( $argstr );
    
    # Look for commonly non-closed tags:
    my $originalTag = $fulltag;
    if( lc($tagname) =~ m/^(br|hr)$/ && $fulltag !~ m/\/>$/ )
    {
      $fulltag =~ s/\>$/ \/>/;
    }# end if()
    
    if( $fulltag =~ m/\/>$/ )
    {
      # It's a "Single" tag:
      my $attrs = $s->_parse_tag_attrs( $argstr );
      my $tag = Apache2::ASP::DOM::Node->new(
        attributes => $attrs,
        tagName    => $tagname,
        fulltag    => $fulltag,
      );
      $parents[-1]->appendChild( $tag );
    }
    elsif( $fulltag =~ m/^<\// )
    {
      # It's an "End" tag:
      pop(@parents);
    }
    else
    {
      # It's the beginning of a "Double" tag:
      $txt =~ m@(<(([a-z_0-9\:]+)\s*(.*?))>(.*?)</\3\s*>)@is; #@
      my $tagname = $3;
      my $argstr = $4;
      my $fulltag = $1;
      my ($innerHTML) = $5;
      my $attrs = $s->_parse_tag_attrs( $argstr );
      my $tag = Apache2::ASP::DOM::Node->new(
        attributes => $attrs,
        tagName    => $tagname,
        innerHTML  => $innerHTML,
        fulltag    => $fulltag,
      );
      $parents[-1]->appendChild( $tag );
      push @parents, $tag;
    }# end if()
    $txt =~ s/\Q$originalTag\E/PARSED/;
  }# end while()
  
  return $doc;
}# end parse()


#==============================================================================
sub _parse_single
{
  my ($s, $txt) = @_;
  
  if(
    $txt =~ m@
      (<(([a-z0-9_\:]+)\s*(.*?))/>)
    @xi #@
  )
  {
    my $tagname = lc($3);
    my $argstr = $4;
    my $fulltag = $1;
    my $attrs = $s->_parse_tag_attrs( $argstr );
    
    return Apache2::ASP::DOM::Node->new(
      attributes => $attrs,
      tagName    => $tagname,
      fulltag    => $fulltag,
    );
  }# end if()
}# end _parse_single()


#==============================================================================
sub _parse_tag_attrs
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
}# end _parse_tag_attrs()


1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::DOM::Parser - Server-side DOM parser for Apache2::ASP

=head1 EXPERIMENTAL STATUS

B<NOTE>: The entire DOM functionality for Apache2::ASP is still under heavy
development and is subject to change in dramatic ways without warning.

B<DO NOT> build anything that involves server-side DOM until it has matured.

=head1 SYNOPSIS

  my $doc = Apache2::ASP::DOM::Parser->parse( $string );

=head1 PUBLIC METHODS

=head2 parse( $string )

Parses C<$string> and returns a L<Apache2::ASP::DOM::Document> object.

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

