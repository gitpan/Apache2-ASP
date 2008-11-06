
package Apache2::ASP::ErrorHandler;

use strict;
use warnings 'all';
use base 'Apache2::ASP::HTTPHandler';
use vars __PACKAGE__->VARS;


#==============================================================================
sub run
{
  my ($s, $context) = @_;
  
  my $error = $Stash->{error};

  my $msg = <<"ERROR";
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html>
<head><title>500 Server Error</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<style type="text/css">
HTML,BODY {
  background-color: #FFFFFF;
}
HTML,BODY,P,DIV {
  font-family: Arial, Helvetica, Sans-Serif;
}
HTML,BODY,P,PRE,DIV {
  font-size: 12px;
}
H1 {
  font-size: 50px;
  font-weight: bold;
}
PRE {
  padding-right: 10px;
  line-height: 16px;
}
#code {
  margin-top: 20px;
  margin-left: 15px;
  width: 95%;
  padding: 10px;
  overflow: auto;
  border: solid 1px #808080;
  background-color: #FFFFCC;
}
.clear {
  clear: both;
}
.label {
  text-align: right;
  padding-right: 5px;
  float: left;
  width: 80px;
  font-weight: bold;
}
.info {
  float: left;
  color: #CC0000;
}
</style>
<body>
<h1>500 Server Error</h1>
<h2>@{[ $error->{title} ]}</h2>
<div><div class="label">File:</div> <div class="info"><code>@{[ $error->{file} ]}</code></div></div>
<div class="clear"></div>
<div><div class="label">Line:</div> <div class="info">@{[ $error->{line} ]}</div></div>
<div class="clear"></div>
<div><div class="label">Time:</div> <div class="info">@{[ HTTP::Date::time2iso() ]}</div></div>
<div class="clear"></div>
<h2>Stacktrace follows below:</h2>
<div id="code"><pre>@{[ $error->{stacktrace} ]}</pre></div>
</body>
</html>
ERROR
  
  $Response->Write( $msg );
  $Server->Mail(
    To              => $Config->errors->mail_errors_to,
    From            => $Config->errors->mail_errors_from,
    Subject         => "Apache2::ASP: Error in @{[ $ENV{HTTP_HOST} ]}@{[ $context->r->uri ]}",
    'content-type'  => 'text/html',
    Message         => $msg,
    smtp            => $Config->errors->smtp_server,
  );

}# end run()

1;# return true:

