
package Apache2::ASP::DOM::Document;

use strict;
use warnings 'all';
use base 'Apache2::ASP::DOM::Node';


1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::DOM::Document - Simple server-side DOM for ASP scripts

=head1 EXPERIMENTAL STATUS

B<NOTE>: The entire DOM functionality for Apache2::ASP is still under heavy
development and is subject to change in dramatic ways without warning.

B<DO NOT> build anything that involves server-side DOM until it has matured.

=head1 SYNOPSIS

  my $doc = $Request->Document;
  
  foreach my $span ( $doc->getElementsByTagName("span") )
  {
    # Do something with $span:
  }# end foreach()

=head1 DESCRIPTION

Server-side DOM allows you to modify the appearance and behavior of elements within
the page during runtime on the server, rather than while the ASP script is coded.

Well, it will, eventually.

=head1 PUBLIC PROPERTIES

All those inherited from L<Apache2::ASP::DOM::Node> as well as:

=head2 documentElement

Returns the root element.

=head1 PUBLIC METHODS

Only those inherited from L<Apache2::ASP::DOM::Node>.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-ASP> to submit bug reports.

=head1 HOMEPAGE

Please visit the Apache2::ASP homepage at L<http://www.devstack.com/> to see examples
of Apache2::ASP in action.

=head1 AUTHOR

John Drago L<mailto:jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut

