
package Apache2::ASP::PostConfigHandler;

use strict;
use warnings 'all';
use Apache2::ASP::GlobalConfig;

sub handler : method
{
  $ENV{APACHE2_ASP_GLOBALCONFIG} = Apache2::ASP::GlobalConfig->new();
  warn "Apache2::ASP::GlobalConfig has been loaded into \$ENV{APACHE2_ASP_GLOBALCONFIG}\n";
  
  return 0;
}# end handler()

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::PostConfigHandler - PerlPostConfigHandler for Apache2::ASP

=head1 SYNOPSIS

  # In your httpd.conf:
  PerlModule            Apache2::ASP::PostConfigHandler
  PerlPostConfigHandler Apache2::ASP::PostConfigHandler

=head1 DESCRIPTION

To lower overhead, C<Apache2::ASP::PostConfigHandler> creates one global L<Apache2::ASP::Config>
object per Apache child, then stores it inside of C<$ENV{APACHE2_ASP_CONFIG}>.

Then it writes a log entry to your server's error log saying what it's done.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-ASP> to submit bug reports.

=head1 HOMEPAGE

Please visit the Apache2::ASP homepage at L<http://apache2-asp.no-ip.org/> to see examples
of Apache2::ASP in action.

=head1 AUTHOR

John Drago L<mailto:jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut
