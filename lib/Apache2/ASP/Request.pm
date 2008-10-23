
package Apache2::ASP::Request;

use strict;
use warnings 'all';
use Carp 'confess';
use Scalar::Util 'weaken';


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  my $context = delete($args{context});
  
  my $s = bless {
    context => $context
  }, $class;
  
  weaken($s->{context});
  return $s;
}# end new()


#==============================================================================
sub context
{
  $Apache2::ASP::HTTPContext::ClassName->current;
}# end context()


#==============================================================================
sub ServerVariables
{
  my $s = shift;
  @_ ? $ENV{$_[0]} : \%ENV;
}# end ServerVariables()


#==============================================================================
sub Form
{
  my $s = shift;
  
  local $SIG{__DIE__} = \&confess;
  my $cgi = $s->context->cgi;
  return {
    map { $_ => $cgi->param($_) } $cgi->param
  };
}# end Form()


#==============================================================================
sub QueryString
{
  my $s = shift;
  
  return $s->context->r->args;
}# end QueryString()


#==============================================================================
sub Cookies
{
  my $s = shift;
  
  return { } unless $s->context->headers_in->{cookie};
  
  my %out = ( );
  foreach my $item ( split /;/, $s->context->headers_in->{cookie} )
  {
    my ( $name, $val ) = map { $s->context->r->unescape( $_ ) } split /\=/, $item;
    $out{$name} = $val;
  }# end foreach()
  
  @_ ? $out{$_[0]} : \%out;
}# end Cookies()


#==============================================================================
sub FileUpload
{
  my ($s, $field, $arg) = @_;
  
  confess "Request.FileUpload called without arguments"
    unless defined($field);
  
  my $cgi = $s->context->cgi;
  
  my $ifh = $cgi->upload($field);
  my %info = ();
  my $upInfo = { };
  
  if( $cgi->isa('Apache2::ASP::SimpleCGI') )
  {
    no warnings 'uninitialized';
    %info = (
      ContentType           => $cgi->upload_info( $field, 'mime' ),
      FileHandle            => $ifh,
      BrowserFile           => $s->Form->{ $field } . "",
      'Content-Disposition' => 'attachment',
      'Mime-Header'         => $cgi->upload_info( $field, 'mime' ),
    );
  }
  else
  {
    $upInfo = $cgi->uploadInfo( $ifh );
    no warnings 'uninitialized';
    %info = (
      ContentType           => $upInfo->{'Content-Type'},
      FileHandle            => $ifh,
      BrowserFile           => $s->Form->{ $field } . "",
      'Content-Disposition' => $upInfo->{'Content-Disposition'},
      'Mime-Header'         => $upInfo->{type},
    );
  }# end if()
  
  if( wantarray )
  {
    return %info;
  }
  else
  {
    if( $arg )
    {
      return $info{ $arg };
    }
    else
    {
      return $ifh;
    }# end if()
  }# end if()

}# end FileUpload()


#==============================================================================
sub DESTROY
{
  my $s = shift;
  undef(%$s);
}# end DESTROY()

1;# return true:

