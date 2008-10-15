
package Apache2::ASP::SimpleCGI;

use strict;
use warnings 'all';
use HTTP::Body;


#==============================================================================
sub new
{
  my ($s, %args) = @_;
  
  my %params = ();
  my %upload_data = ();
  if( length($args{querystring}) )
  {
    foreach my $part ( split /&/, $args{querystring} )
    {
      my ($k,$v) = map { $s->unescape($_) } split /\=/, $part;
      
      if( exists($params{$k}) )
      {
        if( ref($params{$k}) )
        {
          push @{$params{$k}}, $v;
        }
        else
        {
          $params{$k} = [ $params{$k}, $v ];
        }# end if()
      }
      else
      {
        $params{$k} = $v;
      }# end if()
    }# end foreach()
  }# end if()
  
  if( $args{body} )
  {
    my $body = HTTP::Body->new( $args{content_type}, $args{content_length} );
    $body->add( $args{body} );
    
    # Parse form values:
    my $form_info = $body->param || { };
    if( keys(%$form_info) )
    {
      foreach( keys(%$form_info) )
      {
        $params{$_} = $form_info->{$_};
      }# end foreach()
    }# end if()
    
    # Parse uploaded data:
    if( my $uploads = $body->upload )
    {
      foreach my $name ( keys(%$uploads) )
      {
        open my $ifh, '<', $uploads->{$name}->{tempname}
          or die "Cannot open '$uploads->{$name}->{tempname}' for reading: $!";
        $upload_data{$name} = {
          %{$uploads->{$name}},
          'filehandle' => $ifh,
        };
      }# end foreach()
    }# end if()
  }# end if()
  
  return bless {
    params => \%params,
    uploads => \%upload_data,
    %args
  }, $s;
}# end new()


#==============================================================================
sub upload
{
  my ($s, $key) = @_;
  
  no warnings 'uninitialized';
  return exists( $s->{uploads}->{$key} ) ? $s->{uploads}->{$key}->{filehandle} : undef;
}# end upload()


#==============================================================================
sub upload_info
{
  my ($s, $key, $info) = @_;
  
  no warnings 'uninitialized';
  if( exists( $s->{uploads}->{$key} ) )
  {
    my $upload = $s->{uploads}->{$key};
    if( exists( $upload->{$info} ) )
    {
      return $upload->{$info};
    }
    else
    {
      return undef;
    }# end if()
  }
  else
  {
    return undef;
  }# end if()
}# end upload_info()


#==============================================================================
sub param
{
  my ($s, $key) = @_;
  
  if( defined($key) )
  {
    if( ref($s->{params}->{$key}) )
    {
      return wantarray ? @{ $s->{params}->{$key} } : $s->{params}->{$key};
    }
    else
    {
      return $s->{params}->{$key};
    }# end if()
  }
  else
  {
    return keys(%{ $s->{params} });
  }# end if()
}# end param()


#==============================================================================
sub escape
{
  my $toencode = $_[1];
  no warnings 'uninitialized';
  $toencode =~ s/([^a-zA-Z0-9_\-.])/uc sprintf("%%%02x",ord($1))/esg;
  $toencode;
}# end escape()


#==============================================================================
sub unescape
{
  my ($s, $todecode) = @_;
  return unless defined($todecode);
  $todecode =~ tr/+/ /;       # pluses become spaces
  $todecode =~ s/%(?:([0-9a-fA-F]{2})|u([0-9a-fA-F]{4}))/
  defined($1)? chr hex($1) : utf8_chr(hex($2))/ge;
  return $todecode;
}# end unescape()

1;# return true:
