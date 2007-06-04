
package Apache2::ASP::Handler;

use strict;
use warnings 'all';
use vars qw( %modes );

#==============================================================================
sub run
{
  my ($s, $Session, $Request, $Response, $Server, $Application) = @_;
  
  # Call our extension hooks:
  if( my $mode = $Request->Form('mode') )
  {
    if( exists($modes{ $mode }) && defined($modes{ $mode }) )
    {
      return $modes{$mode}->( @_ );
    }
    else
    {
      $Response->Write("Unknown mode '$mode'.");
    }# end if()
  }
  else
  {
    $Response->Write("This is the default handler response.");
  }# end if()
  
}# end run()


#==============================================================================
sub register_mode
{
  my ($s, %info) = @_;
  
  $modes{ $info{name} } = $info{handler};
}# end register_mode()

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::Handler - Base class for all Apache2::ASP handlers

=head1 SYNOPSIS

  package MyHandler;
  
  use strict;
  use base 'Apache2::ASP::Handler';
  
  sub run {
    my ($s, $Session, $Request, $Response, $Server, $Application) = @_;
    
    $Response->Write("Hello, world!.");
  }# end run()
  
  1;# return true:

Access C<MyHandler> via the URL C</handlers/MyHandler> on your website.

=head1 DESCRIPTION

Apache2::ASP::Handler offers an "in-between" ASP environment in which there 
is no Perl embedded within HTML (via <% and %> tags) but you still get
the ASP objects (C<$Request>, C<$Response>, C<$Session>, C<$Server> and C<$Application>).

Handlers are useful for things like form processing when no HTML content is
sent back to the client (because the client is redirected to another ASP instead).

=head1 PROTECTED METHODS

The following methods are intended for subclasses of C<Apache2::ASP::Handler>.

=head2 register_mode( %args )

Allows your Handler class to handle "mode=xxx" requests for other Handlers.

Example:

  package MyHandler;
  
  use base 'SomeDefaultHandler';
  
  __PACKAGE__->register_mode(
    name    => 'mymode',
    handler => \&do_mymode,
  );
  
  # Accessible via URLs such as /handler/SomeDefaultHandler?mode=mymode
  sub do_mymode
  {
    my ($Session, $Request, $Response, $Server, $Application) = @_;
    
    # ... do stuff ...
    $Response->Write("mymode is successful!");
  }# end do_mymode()

Any call to C</media/file123.gif?mode=mymode> will execute your C<do_mymode()> method.

This is useful for generating image thumbnails - i.e. C</media/file123.gif?mode=thumb&max_w=100&max_h=80>

The rest is left as an exercise for the reader.

=head1 AUTHOR

John Drago L<jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut
