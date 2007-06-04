
package Apache2::ASP::Application;

use strict;
use warnings;
use Apache2::ASP::Config;


#==============================================================================
sub new
{
  my ($s) = @_;
  
  die "new() not implemented";
}# end new()


#==============================================================================
sub save
{
  my ($s) = @_;
  
  die "save() not implemented";
}# end new()


#==============================================================================
sub DESTROY
{
  # XXX: Save data to persistent storage.
  my $s = shift;
  $s->save;
}# end DESTROY()

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::Application - Shared data for Apache2::ASP applications.

=head1 DESCRIPTION

The global C<$Application> object is an instance of C<Apache2::ASP::Application>.

Placing data inside the C<$Application> object makes it available to all future
requests to that web application.

=head1 SEE ALSO

Make sure to take a look at L<Apache2::ASP::Application::MySQL> since it is the 
default Application state manager.

=head1 AUTHOR

John Drago L<jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut
