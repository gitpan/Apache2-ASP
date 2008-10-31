
package Apache2::ASP::ConfigParser;

use strict;
use warnings 'all';
use Apache2::ASP::Config;


#==============================================================================
sub new
{
  my ($class) = @_;
  
  return bless { }, $class;
}# end new()


#==============================================================================
sub parse
{
  my ($s, $doc, $root) = @_;
  
  # Start out with the <system>
  SYSTEM: {
    $doc->{system}->{libs} ||= { };
    if( $doc->{system}->{libs}->{lib} )
    {
      $doc->{system}->{libs}->{lib} = [ $doc->{system}->{libs}->{lib} ]
        unless ref($doc->{system}->{libs}->{lib}) eq 'ARRAY';
    }
    else
    {
      $doc->{system}->{libs}->{lib} = [ ];
    }# end if()
    
    $doc->{system}->{load_modules} ||= { };
    if( $doc->{system}->{load_modules}->{module} )
    {
      $doc->{system}->{load_modules}->{module} = [ $doc->{system}->{load_modules}->{module} ]
        unless ref($doc->{system}->{load_modules}->{module}) eq 'ARRAY';
    }
    else
    {
      $doc->{system}->{load_modules}->{module} = [ ];
    }# end if()
    
    $doc->{system}->{env_vars} ||= [ ];
    if( $doc->{system}->{env_vars}->{var} )
    {
      $doc->{system}->{env_vars} = [ $doc->{system}->{env_vars}->{var} ]
        unless ref($doc->{system}->{env_vars}->{var}) eq 'ARRAY';
    }
    else
    {
      $doc->{system}->{env_vars}= [ ];
    }# end if()
    
    # Post-processor:
    $doc->{system}->{post_processors} ||= { };
    if( $doc->{system}->{post_processors}->{class} )
    {
      $doc->{system}->{post_processors}->{class} = [ $doc->{system}->{post_processors}->{class} ]
        unless ref($doc->{system}->{post_processors}->{class}) eq 'ARRAY';
    }
    else
    {
      $doc->{system}->{post_processors}->{class} = [ ];
    }# end if()
  };
  
  WEB: {
    $doc->{web}->{settings} ||= { };
    $doc->{web}->{request_filters} ||= { };
    if( $doc->{web}->{request_filters}->{filter} )
    {
      $doc->{web}->{request_filters}->{filter} = [ $doc->{web}->{request_filters}->{filter} ]
        unless ref($doc->{web}->{request_filters}->{filter}) eq 'ARRAY';
    }
    else
    {
      $doc->{web}->{request_filters}->{filter} = [ ];
    }# end if()
  };
  
  DATA_CONNECTIONS: {
    $doc->{data_connections} ||= { };
    $doc->{data_connections}->{session} ||= { };
    $doc->{data_connections}->{application} ||= { };
    $doc->{data_connections}->{main} ||= { };
  };
  
  my $config = Apache2::ASP::Config->new( $doc, $root );
  
  # Now do any post-processing:
  foreach my $class ( $config->system->post_processors )
  {
    (my $file = "$class.pm") =~ s/::/\//;
    require $file unless $INC{$file};
    $config = $class->new()->post_process( $config );
  }# end foreach()
  
  return $config;
}# end parse()

1;# return true:

