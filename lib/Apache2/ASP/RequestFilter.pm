
package Apache2::ASP::RequestFilter;

use strict;
use warnings 'all';
use base qw( Apache2::ASP::FormHandler );
use vars qw(
  $Request  $Application
  $Response $Server
  $Session  $Form
  $Config
);

#==============================================================================
sub run
{
  my ($s) = @_;
  
  warn "Filter class $s does not override the 'run()' method.";
  
  return -1;
}# end run()

1;# return true:

__END__

=head1 NAME

Apache2::ASP::RequestFilter - Chained request filtering for Apache2::ASP

=head1 SYNOPSIS

In your apache2_asp_config.xml:

  <config>
    <web_application>
    ...
      <settings>
        ...
      </settings>
      <request_filters>
        <filter>
          <uri_match>/members_only/.*</uri_match>
          <class>MyWebApp::MemberFilter</class>
        </filter>
        <filter>
          <uri_equals>/disabled_page.asp</uri_equals>
          <class>MyWebApp::DisabledPage</class>
        </filter>
      </request_filters>
    ...
    </web_application>
  </config>

Here we define two possible filters and specify which RequestFilter subclasses should handle requests to their respective URIs.

Definition for C<MyWebApp::MemberFilter>:

  package MyWebApp::MemberFilter;
  
  use strict;
  use warnings 'all';
  use base qw( Apache2::ASP::RequestFilter );
  use vars qw(
    $Request  $Application
    $Response $Server
    $Session  $Form
    $Config
  );
  
  
  #==============================================================================
  sub run
  {
    my ($s) = @_;
    
    if( ! $Session->{logged_in} )
    {
      # Get outta here!
      $Response->Redirect("/login.asp");
      
      # Same as Apache2::Const::OK:
      return 0;
    }
    else
    {
      # Same as Apache2::Const::DECLINED:
      return $Response->Declined;
    }# end if()
    
  }# end run()
  
  1;# return true:

The definition for C<MyWebApp::DisabledPage> would look fairly similar:

  package MyWebApp::DisabledPage;
  
  use strict;
  use warnings 'all';
  use base qw( Apache2::ASP::RequestFilter );
  use vars qw(
    $Request  $Application
    $Response $Server
    $Session  $Form
    $Config
  );
  
  
  #==============================================================================
  sub run
  {
    my ($s) = @_;
    
    $Response->Redirect("/login.asp");
    
    # Return '0' to tell Apache to stop processing the request:
    return 0;
  }# end run()
  
  1;# return true:

=head1 DESCRIPTION

The motivation for this class came after using Apache2::ASP on a fairly large project
which resulted in a great deal of complex logic to control users' navigation through
a long series of forms.

We needed a B<maintainable> way to control users' progress through the forms.

Enter C<Apache2::ASP::RequestFilter>.  With a few lines of configuration we can wipe out
dozens of lines of C<if()> this and C<if()> that.  We get something that, six months from
now, we can look at and still understand (and confidently update).

=head1 METHODS

=head2 run( )

You must override this one method.

=head1 RETURN VALUES

B<VERY IMPORTANT!!!>

This gets its own section because it is very important.

The C<run()> method should either return C<<$Response->Declined>> or some other C<Apache2::Const::*>-compatible value.

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
