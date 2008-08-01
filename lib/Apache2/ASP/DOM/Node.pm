
package Apache2::ASP::DOM::Node;

use strict;
use warnings 'all';
use base 'Apache2::ASP::DOM::Parser';
use Carp 'confess';
use Scalar::Util qw( weaken );


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  $args{parentNode} ||= undef;
  weaken($args{parentNode}) if ref($args{parentNode});
  $args{childNodes} = [ ];
  $args{attributes} ||= { };
  $args{id}         ||= undef;
  $args{tagName}    ||= undef;
  $args{$_} = $args{attributes}->{$_}
    foreach keys( %{$args{attributes}} );
  delete($args{attributes});
  
  $args{runat} = lc($args{runat}) if exists($args{runat}) && defined($args{runat});
  if( exists($args{runat}) && $args{runat} eq 'server' && ! $args{id} )
  {
    die "runat=\"server\" requires a valid id attribute for $args{fulltag}";
  }# end if()
  
  my $s = bless \%args, $class;
  return $s;
}# end new()


#==============================================================================
sub getElementById
{
  my ($s, $id) = @_;
  
  if( my ($child) = grep { defined($_->id) && $_->id eq $id } $s->childNodes )
  {
    return $child;
  }# end if()
  
  # Failed - try our children:
  foreach my $child ( $s->childNodes )
  {
    if( my $obj = $child->getElementById( $id ) )
    {
      return $obj;
    }# end if()
  }# end foreach()
  
  return;
}# end getElementById()


#==============================================================================
sub getElementsByTagName
{
  my ($s, $tagName) = @_;
  $tagName = lc($tagName);
  
  my @tags = ( );
  if( my ($child) = grep { defined($_->tagName) && lc($_->tagName) eq $tagName } $s->childNodes )
  {
    push @tags, $child;
  }# end if()
  
  # Failed - try our children:
  foreach my $child ( $s->childNodes )
  {
    if( my @childTags = $child->getElementsByTagName( $tagName ) )
    {
      push @tags, @childTags;
    }# end if()
  }# end foreach()
  
  return unless @tags;
  return @tags;
}# end getElementsByTagName()


#==============================================================================
sub childNodes
{
  @{ $_[0]->{childNodes} };
}# end childNodes()


#==============================================================================
sub parentNode
{
  my $s = shift;
  if( @_ )
  {
    weaken( $s->{parentNode} = shift );
  }# end if()
  $s->{parentNode};
}# end parentNode()


#==============================================================================
sub appendChild
{
  my ($s, $child) = @_;
  
  $child->parentNode( $s );
  push @{$s->{childNodes}}, $child;
}# end appendChild()


#==============================================================================
sub AUTOLOAD
{
  my $s = shift;
  our $AUTOLOAD;
  my ($name) = $AUTOLOAD =~ m/([^:]+)$/;
  
  if( @_ )
  {
    $s->{$name} = shift;
  }
  else
  {
    exists($s->{$name})
      ? return $s->{$name}
      : confess "Unknown attribute or method '$name' for tag $s->{tagName}";
  }# end if()
}# end AUTOLOAD()


#==============================================================================
sub DESTROY
{
  my $s = shift;
  delete($s->{$_}) foreach keys(%$s);
}# end DESTROY()

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::DOM::Node - A DOM Node for server-side ASP DOM

=head1 EXPERIMENTAL STATUS

B<NOTE>: The entire DOM functionality for Apache2::ASP is still under heavy
development and is subject to change in dramatic ways without warning.

B<DO NOT> build anything that involves server-side DOM until it has matured.

=head1 SYNOPSIS

  foreach my $node ( $Request->Document->documentElement->childNodes )
  {
    print $node->tagName;
    print $node->innerHTML;
    $node->parentNode->childNodes;
    $node->childNodes;
    $node->appendChild( ... );
    my $otherNode = $node->getElementById("some-id");
    
    my @divs = $node->getElementsByTagName("div");
  }# end foreach()

=head1 DESCRIPTION

=head1 PUBLIC PROPERTIES

=head2 tagName

Returns the tagName - i.e. "b" or "div" or "hr" or "My:Tag"

=head2 innerHTML

Returns the contents of the tag.

=head2 parentNode

returns C<undef> if there is no parentNode, or the Node that the current Node
is a child of.

=head2 childNodes

Returns a list of all children of the current node.

=head1 PUBLIC METHODS

=head2 appendChild( $node )

Adds the supplied node to the childNodes array.

=head2 getElementById( $id )

Searches the current node (and all childNodes, recursively) for an element by that id.

=head2 getElementsByTagname( $tagName )

Searches the current node (and all childNodes, recursively) for all elements by that
tagName.

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

