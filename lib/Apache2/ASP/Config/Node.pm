
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
sub keys { keys(%{ $_[0] }) }


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
    return $s->{ $key };
  }
  else
  {
#    die "Invalid config.node property '$key'";
use Carp 'confess';
		confess "Config node '$s->{__path}' has no property named '$key'";
  }# end if()
}# end AUTOLOAD()


#==============================================================================
sub DESTROY { }

1;# return true:
