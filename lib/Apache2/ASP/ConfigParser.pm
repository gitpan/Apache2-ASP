
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
  
  ENV: {
    $doc->{env_vars} ||= { };
    if( $doc->{env_vars}->{var} )
    {
      $doc->{env_vars} = [ $doc->{env_vars}->{var} ]
        unless ref($doc->{env_vars}->{var}) eq 'ARRAY';
    }
    else
    {
      $doc->{env_vars}= [ ];
    }# end if()
  };
  
  DATA_CONNECTIONS: {
    $doc->{data_connections} ||= { };
    $doc->{data_connections}->{session} ||= { };
    $doc->{data_connections}->{application} ||= { };
    $doc->{data_connections}->{main} ||= { };
  };
  
  my $config = Apache2::ASP::Config->new( $doc, $root );
  
  push @INC, $config->web->handler_root;
  
  return $config;
}# end parse()

1;# return true:

