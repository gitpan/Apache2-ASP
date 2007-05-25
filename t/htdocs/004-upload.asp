<%
  my $file = $Request->FileUpload('filename');
  $Response->Write( -s $file );
%>
