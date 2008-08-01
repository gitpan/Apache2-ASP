
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

