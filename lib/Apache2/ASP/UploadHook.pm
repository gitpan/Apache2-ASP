
package Apache2::ASP::UploadHook;

use strict;
use warnings 'all';
use Apache2::ASP::UploadHookArgs;
use Time::HiRes 'gettimeofday';


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  # Sanity check here:
  $args{asp} && ref($args{asp}) && UNIVERSAL::isa($args{asp}, 'Apache2::ASP::Base' )
    or die "Required parameter 'asp' (an Apache2::ASP::Base object) was not provided.";
  $args{handler_class} && UNIVERSAL::isa($args{handler_class}, 'Apache2::ASP::UploadHandler')
    or die "Required parameter 'handler_class' (an Apache2::ASP::UploadHandler object) was not provided.";
  
  return bless \%args, $class;
}# end new()


#==============================================================================
sub hook
{
  my ($s, $upload, $data) = @_;
  
  my $length_received = defined($data) ? length($data) : 0;
  $s->{asp}->r->pnotes( total_loaded => ($s->{asp}->r->pnotes('total_loaded') || 0) + $length_received);
  my $percent_complete = sprintf("%.2f", $s->{asp}->r->pnotes('total_loaded') / $ENV{CONTENT_LENGTH} * 100 );
  
  # Mark our start time, so we can make our calculations:
  my $start_time = $s->{asp}->r->pnotes('upload_start_time');
  if( ! $start_time )
  {
    $start_time = gettimeofday();
    $s->{asp}->r->pnotes('upload_start_time' => $start_time);
  }# end if()
  
  # Calculate elapsed, total expected and remaining time, etc:
  my $elapsed_time        = gettimeofday() - $start_time;
  my $bytes_per_second    = $s->{asp}->r->pnotes('total_loaded') / $elapsed_time;
  $bytes_per_second       ||= 1;
  my $total_expected_time = int( ($ENV{CONTENT_LENGTH} - $length_received) / $bytes_per_second );
  my $time_remaining      = int( (100 - $percent_complete) * $total_expected_time / 100 );
  $time_remaining         = 0 if $time_remaining < 0;
  
  # Use an object, not just a hashref:
  my $Upload = Apache2::ASP::UploadHookArgs->new(
    upload              => $upload,
    percent_complete    => $percent_complete,
    elapsed_time        => $elapsed_time,
    total_expected_time => $total_expected_time,
    time_remaining      => $time_remaining,
    length_received     => $length_received,
    data                => defined($data) ? $data : undef,
  );
  
  # Init the upload:
  my $did_init = $s->{asp}->r->pnotes('did_init');
  if( ! $did_init )
  {
    $s->{asp}->r->pnotes( did_init => 1 );
    $s->{handler_class}->upload_start( $s->{asp}, $Upload );
    
    # End the upload if we are done:
    $s->{asp}->r->push_handlers(PerlCleanupHandler => sub {
      my $id = $s->{asp}->request->Form->{upload_id};
      delete($s->{asp}->session->{"$id\_$_"})
        foreach keys(%$Upload);
      $s->{asp}->session->save;
    });
  }# end if()
  
  if( $length_received <= 0 )
  {
    $s->{handler_class}->init_asp_objects( $s->{asp} );
    $s->{handler_class}->upload_end( $s->{asp}, $Upload );
  }# end if()
  
  # Call the hook:
  $s->{handler_class}->upload_hook( $s->{asp}, $Upload );
}# end hook()


1;# return true:

__END__

=pod

=head1 NAME

Apache2::ASP::UploadHook - Default upload hook for Apache2::ASP

=head1 SYNOPSIS

  # Internal use only.

=head1 DESCRIPTION

This class smoothes out dealing with file uploads.  It abstracts some of the boring 
aspects of doing upload rate calculations and such.  It also calls the current
L<Apache2::ASP::UploadHandler> subclass's methods (upload_start, upload_hook, upload_end)
at the appropriate times.

=head1 PUBLIC METHODS

=head2 new( %args )

C<%args> should contain the following members:

=over 4

=item * asp

An ASP object.

=item * handler_class

The name of the L<Apache2::ASP::UploadHandler> subclass handling the current request.

=back

=head1 OVERRIDABLE METHODS

=head2 hook( $upload, $data )

The C<hook> method is called several times during an upload.  Depending on the status
of the upload (starting, continuing, ending) it calls various methods in the
L<Apache2::ASP::UploadHandler> subclass handling the current request.

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
