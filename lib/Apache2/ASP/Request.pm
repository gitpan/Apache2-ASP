
package Apache2::ASP::Request;

use strict;
use warnings 'all';
use Carp 'confess';


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  my $s = bless {
  }, $class;
  
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
  
  local $SIG{__DIE__} = \&Carp::confess;
  my $cgi = $s->context->cgi;
  my $form = { };
  foreach my $param ( $cgi->param )
  {
    if( exists($form->{$param}) )
    {
      # We've already seen this param:
      my $data = delete($form->{$param});
      # Make it into an arrayref unless it already is:
      $data = [ $data ] unless ref($data) eq 'ARRAY';
      push @$data, $cgi->param($param);
      $form->{$param} = $data;
    }
    else
    {
      $form->{$param} = $cgi->param($param);
    }# end if()
  }# end foreach()
  return $s->{_form} = $form;
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

=pod

=head1 NAME

Apache2::ASP::Request - Incoming request object.

=head1 SYNOPSIS

  my $form_args = $Request->Form;
  
  my $querystring = $Request->QueryString;
  
  my $cookies = $Request->Cookies;
  
  my $cookie = $Request->Cookies('name');
  
  my $vars = $Request->ServerVariables;
  
  my $var = $Request->ServerVariables('HTTP_HOST');

=head1 DESCRIPTION

The request represents a wrapper around incoming form, querystring and cookie data.

=head1 PUBLIC METHODS

=head2 ServerVariables( [$name] )

If called with no arguments, returns C<%ENV>.  If called with an argument, returns
C<$ENV{$name}> where C<$name> is the value of the argument.

=head2 Cookies( [$name] )

If called with no arguments, returns a hash of all cookies.  Otherwise, returns
the value of the cookie named C<$name>.

=head1 PUBLIC PROPERTIES

=head2 Form

Returns a hashref of all querystring and form data.

=head2 QueryString

Returns the querystring portion of the current request.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-ASP> to submit bug reports.

=head1 HOMEPAGE

Please visit the Apache2::ASP homepage at L<http://www.devstack.com/> to see examples
of Apache2::ASP in action.

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 COPYRIGHT

Copyright 2008 John Drago.  All rights reserved.

=head1 LICENSE

This software is Free software and is licensed under the same terms as perl itself.

=cut

