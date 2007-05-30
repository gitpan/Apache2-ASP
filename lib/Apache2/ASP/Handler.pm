
package Apache2::ASP::Handler;

our $VERSION = 0.08;

use strict;
use warnings 'all';

#==============================================================================
sub run
{
  my ($s, $Session, $Request, $Response, $Server, $Application) = @_;
  
  $Response->Write("This is the default handler response.");
  
}# end run()

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

=head1 AUTHOR

John Drago L<jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut
