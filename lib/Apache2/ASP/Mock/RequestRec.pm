
package Apache2::ASP::Mock::RequestRec;

use strict;
use warnings 'all';
use Carp 'confess';
use Apache2::ASP::Mock::Connection;


#==============================================================================
sub new
{
  my ($class) = shift;
  
  return bless {
    buffer => '',
    uri    => '',
    headers_out => { },
    headers_in  => { },
    pnotes => { },
    cleanup_handlers => [ ],
  }, $class;
}# end new()


#==============================================================================
sub push_handlers
{
  my ($s, $ref, @args) = @_;
  
  push @{$s->{cleanup_handlers}}, {
    subref => $ref,
    args   => \@args,
  };
}# end push_handlers()


#==============================================================================
sub filename
{
  my $s = shift;
  
  my $config = Apache2::ASP::HTTPContext->current->config;
  
  return $config->web->www_root . $s->uri;
}# end filename()


#==============================================================================
sub pnotes
{
  my $s = shift;
  my $key = shift;
  
  @_ ? $s->{pnotes}->{$key} = shift : $s->{pnotes}->{$key};
}# end pnotes()


#==============================================================================
sub buffer
{
  $_[0]->{buffer};
}# end buffer()


#==============================================================================
sub uri
{
  my $s = shift;
  
  if( @_ )
  {
    $s->{uri} = shift;
  }
  else
  {
    return $s->{uri};
  }# end if()
}# end uri()


#==============================================================================
sub args
{
  my $s = shift;
  @_ ? $s->{args} = shift : $s->{args};
}# end args()


#==============================================================================
sub method
{
  my $s = shift;
  @_ ? $s->{method} = shift : $s->{method};
}# end method()


#==============================================================================
sub headers_out
{
  $_[0]->{headers_out};
}# end headers_out()


#==============================================================================
sub headers_in
{
  $_[0]->{headers_in};
}# end headers_out()


#==============================================================================
sub send_headers
{
  my $s = shift;
  
  confess "Already sent headers" if $s->{_sent_headers};
  my $buffer = delete($s->{buffer});
  $s->print( join "\n", map { "$_: $s->{headers_out}->{$_}" } keys(%{$s->{headers_out}}) );
  $s->{buffer} = $buffer;
  $s->{_sent_headers} = 1;
}# end send_headers()


#==============================================================================
sub content_type
{
  my $s = shift;
  @_ ? $s->{content_type} = shift : $s->{content_type};
}# end content_type()


#==============================================================================
sub print
{
  $_[0]->{buffer} .= $_[1];
}# end print()


#==============================================================================
sub rflush
{
  my $s = shift;
#warn "$s: rflush()";
}# end rflush()


#==============================================================================
sub connection
{
  return Apache2::ASP::Mock::Connection->new;
}# end connection()

1;# return true:

