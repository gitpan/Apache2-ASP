
package Apache2::ASP::Config;

use strict;
use warnings 'all';
use Carp 'confess';
use base 'Apache2::ASP::ConfigNode';


#==============================================================================
sub new
{
  my ($class, $ref, $root) = @_;
  
  my $s = $class->SUPER::new( $ref );
  
  $s->init_server_root( $root );
  return $s;
}# end new()


#==============================================================================
sub init_server_root
{
  my ($s, $root) = @_;
  
  foreach( @{ $s->{system}->{libs}->{lib} } )
  {
    $_ =~ s/\@ServerRoot\@/$root/;
  }# end foreach()
  
  foreach( %{ $s->{web}->{settings} } )
  {
    next unless exists(($s->{web}->{settings}->{$_})) && defined($s->{web}->{settings}->{$_});
    $s->{web}->{settings}->{$_} =~ s/\@ServerRoot\@/$root/;
  }# end foreach()
  
  foreach my $key (qw/ application handler media_manager_upload www page_cache /)
  {
    $s->{web}->{"$key\_root"} =~ s/\@ServerRoot\@/$root/
      if $s->{web}->{"$key\_root"};
  }# end foreach()
}# end init_server_root()


1;# return true:

