
package Apache2::ASP::Mock::RequestRec;

use strict;
use warnings 'all';
use Carp 'confess';
use Apache2::ASP::Mock::Connection;
use Apache2::ASP::Mock::Pool;


#==============================================================================
sub new
{
  my ($class) = shift;
  
  return bless {
    buffer            => '',
    uri               => '',
    headers_out       => { },
    headers_in        => { },
    pnotes            => { },
    status            => 200,
    cleanup_handlers  => [ ],
    pool              => Apache2::ASP::Mock::Pool->new(),
    connection        => Apache2::ASP::Mock::Connection->new(),
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
sub pool
{
  $_[0]->{pool};
}# end buffer()


#==============================================================================
sub status
{
  my $s = shift;
  
  @_ ? $s->{status} = shift : $s->{status};
}# end status()


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
  
  # We partition the "_sent_headers" values by URI, because in testing,
  # sometimes the same requestrec is re-used.  Response->Include was causing
  # this to confess() when really there was no problem:
  confess "Already sent headers"
    if $s->{"_sent_headers:$ENV{REQUEST_URI}"}++;
  my $buffer = delete($s->{buffer});
  $s->print( join "\n", map { "$_: $s->{headers_out}->{$_}" } keys(%{$s->{headers_out}}) );
  $s->{buffer} = $buffer;
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
  $_[0]->{connection};
}# end connection()

1;# return true:

