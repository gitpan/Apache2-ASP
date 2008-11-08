
package Apache2::ASP;

use strict;
use warnings 'all';
use vars '$VERSION';

$VERSION = '2.00_20';

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP - ASP for Perl, reloaded.

=head1 WARNING - ALPHA SOFTWARE!

This software is still considered Alpha (or Pre-Beta) and should *NOT* yet be
used for anything except for testing.

=head1 SYNOPSIS

  1: use Apache2::ASP;
  2: ???
  3: Profit!!

=head1 DESCRIPTION

Apache2::ASP scales out well and has brought the ASP programming model to Perl 
in a new way.

This rewrite had a few major goals:

=over 4

=item * Master Pages

Like ASP.Net has, including nested Master Pages.

=item * Partial-page caching

Like ASP.Net has.

=item * Better configuration

The original config format was unsatisfactory.

=item * Handle multiple VirtualHosts better.

Configuration was the root of this problem.

=item * Better performance

Server resources were being wasted on unnecessary activities like storing
session state even when it had not changed, etc.

=back

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

