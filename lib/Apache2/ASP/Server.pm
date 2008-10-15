
package Apache2::ASP::Server;

use strict;
use warnings 'all';
use Mail::Sendmail;


#==============================================================================
sub new
{
  my ($class, %args) = @_;

  my $s = bless { }, $class;
  
  return $s;
}# end new()


#==============================================================================
sub context
{
  Apache2::ASP::HTTPContext->current;
}# end context()


#==============================================================================
# Shamelessly ripped off from Apache::ASP::Server, by Joshua Chamas,
# who shamelessly ripped it off from CGI.pm, by Lincoln D. Stein.
# :)
sub URLEncode
{
  my $toencode = $_[1];
  no warnings 'uninitialized';
  $toencode =~ s/([^a-zA-Z0-9_\-.])/uc sprintf("%%%02x",ord($1))/esg;
  $toencode;
}# end URLEncode()


#==============================================================================
sub URLDecode
{
  my ($s, $todecode) = @_;
  return unless defined($todecode);
  $todecode =~ tr/+/ /;       # pluses become spaces
  $todecode =~ s/%(?:([0-9a-fA-F]{2})|u([0-9a-fA-F]{4}))/
  defined($1)? chr hex($1) : utf8_chr(hex($2))/ge;
  return $todecode;
}# end URLDecode()


#==============================================================================
sub HTMLEncode
{
  my ($s, $str) = @_;
  no warnings 'uninitialized';
  $str =~ s/&/&amp;/g;
  $str =~ s/</&lt;/g;
  $str =~ s/>/&gt;/g;
  $str =~ s/"/&quot;/g;
  $str =~ s/'/&#39;/g;
  return $str;
}# end HTMLEncode()


#==============================================================================
sub HTMLDecode
{
  my ($s, $str) = @_;
  no warnings 'uninitialized';
  $str =~ s/&lt;/</g;
  $str =~ s/&gt;/>/g;
  $str =~ s/&quot;/"/g;
  $str =~ s/&amp;/&/g;
  return $str;
}# end HTMLEncode()


#==============================================================================
sub MapPath
{
  my ($s, $path) = @_;
  
  return unless defined($path);
  
  $s->context->config->web->www_root . $path;
}# end MapPath()


#==============================================================================
sub Mail
{
  my ($s, %args) = @_;
  
  # XXX: Base64-encode the content, and update the content-type to reflect that
  # if content-type === 'text/html'.
  # XXX: Consider updating this so that we can send attachments as well.
  Mail::Sendmail::sendmail( %args );
}# end Mail()


#==============================================================================
sub RegisterCleanup;
#{
#  my ($s, $sub) = @_;
#  
#  # This is too tightly-coupled:
#  $s->context->r->pool->cleanup_register( $sub );
#}# end RegisterCleanup()


#==============================================================================
sub DESTROY
{
  my $s = shift;
  
  undef(%$s);
}# end DESTROY()

1;# return true:


