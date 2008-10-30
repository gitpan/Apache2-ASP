
package Apache2::ASP::UploadHook;

use strict;
use warnings 'all';
use Apache2::ASP::HTTPContext;
use Carp 'confess';
use Time::HiRes 'gettimeofday';
use Apache2::ASP::UploadHookArgs;


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  foreach(qw/ handler_class /)
  {
    confess "Required param '$_' was not provided"
      unless defined($args{$_});
  }# end foreach()
  return bless \%args, $class;
}# end new()


#==============================================================================
sub context
{
  Apache2::ASP::HTTPContext->current;
}# end context()


#==============================================================================
sub hook
{
  my ($s, $upload, $data) = @_;
  
  my $length_received = defined($data) ? length($data) : 0;
  my $context = $s->context;
  my $CONTENT_LENGTH = $ENV{CONTENT_LENGTH} || $context->r->pnotes('content_length');
  my $total_loaded = ($context->r->pnotes('total_loaded') || 0) + $length_received;
  $context->r->pnotes( total_loaded => $total_loaded);
  my $percent_complete = sprintf("%.2f", $total_loaded / $CONTENT_LENGTH * 100 );
#warn "___Total: '$CONTENT_LENGTH' | Loaded: '$total_loaded' | Complete: $percent_complete%\n";
  
  # Mark our start time, so we can make our calculations:
  my $start_time = $context->r->pnotes('upload_start_time');
  if( ! $start_time )
  {
    $start_time = gettimeofday();
    $context->r->pnotes('upload_start_time' => $start_time);
  }# end if()
  
  
  
  # Calculate elapsed, total expected and remaining time, etc:
  my $elapsed_time        = gettimeofday() - $start_time;
  my $bytes_per_second    = $context->r->pnotes('total_loaded') / $elapsed_time;
  $bytes_per_second       ||= 1;
  my $total_expected_time = int( ($CONTENT_LENGTH - $length_received) / $bytes_per_second );
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
  my $did_init = $context->r->pnotes('did_init');
  if( ! $did_init )
  {
    $context->r->pnotes( did_init => 1 );

    $s->{handler_class}->upload_start( $context, $Upload )
      or return;
    
    # End the upload if we are done:
    $context->r->push_handlers(PerlCleanupHandler => sub {
      delete($context->session->{$_})
        foreach keys(%$Upload);
      $context->session->save;
    });
  }# end if()
  
  if( $length_received <= 0 )
  {
    $s->{handler_class}->init_asp_objects( $context );
    $s->{handler_class}->upload_end( $context, $Upload );
  }# end if()
  
  # Call the hook:
  $s->{handler_class}->upload_hook( $context, $Upload );
}# end hook()

1;# return true:

