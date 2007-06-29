
package Apache2::ASP::FormHandler;

use strict;
use warnings 'all';
use base 'Apache2::ASP::Handler';

use vars qw(
  %modes
  $Request $Response
  $Session $Application
  $Server $Form
  $Config
);

1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::FormHandler - Base class for all "form" handlers.

=head1 SYNOPSIS

  package MyFormHandler;
  
  use strict;
  use base 'Apache2::ASP::FormHandler';
  
  use vars qw(
    %modes
    $Request $Response
    $Session $Application
    $Server $Form
    $Config
  );
  
  sub run
  {
    my ($s, $asp) = @_;
    
    # Do stuff, then:
    $Response->Redirect("/anotherpage.asp");
    
    # When the user gets to '/anotherpage.asp' all fields with names that
    # match a key in $Form will be filled out, automatically.
  }# end run()
  
  1;

=head1 DESCRIPTION

If your Handler processes form data that should be automatically filled in
on another page's form fields, then make sure it is derived from C<Apache2::ASP::FormHandler>.

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
