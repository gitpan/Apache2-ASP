
package Apache2::ASP::Config::Node;

use strict;
use warnings 'all';

#==============================================================================
sub new
{
  my ($class, %args) = @_;
  my $s = bless \%args, $class;
	
	$s->init_keys();
	
	return $s;
}# end new()


#==============================================================================
sub keys { eval { keys(%{ $_[0] }) } }


#==============================================================================
sub init_keys
{
	my $s = shift;
	
	foreach my $key ( grep { ref($s->{$_}) } $s->keys )
	{
		if( ref($s->{$key}) eq 'HASH' )
		{
			$s->{$key} = Apache2::ASP::Config::Node->new( %{ $s->{$key} }, __path => "$s->{__path}.$key" );
		}
		elsif( ref($s->{$key}) eq 'ARRAY' )
		{
			for( 0...scalar(@{$s->{$key}}) - 1 )
			{
				$s->{$key}->[$_] = Apache2::ASP::Config::Node->new( %{ $s->{$key}->[$_] }, __path => "$s->{__path}.$key" );
			}# end foreach()
		}# end if()
	}# end foreach()
}# end init_keys()


#==============================================================================
# Discourage the use of public hash notation - use $node->property_name instead:
sub AUTOLOAD
{
  my $s = shift;
  our $AUTOLOAD;
  my ($key) = $AUTOLOAD =~ m/::([^:]+)$/;
  if( exists($s->{ $key }) )
  {
    return $s->{$key};
  }
  else
  {
    require Carp;
		Carp::confess( "Config node '$s->{__path}' has no property named '$key'" );
  }# end if()
}# end AUTOLOAD()


#==============================================================================
sub DESTROY { }

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::Config::Node - A single node in a config tree

=head1 SYNOPSIS

Not used directly.

=head1 DESCRIPTION

The C<Apache2::ASP::Config::Node> class represents a single node in a config tree.  Nodes can "contain" other "child" nodes.

=head1 PUBLIC METHODS

=head2 keys( )

Returns the list of names of the current node's child-nodes.

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
