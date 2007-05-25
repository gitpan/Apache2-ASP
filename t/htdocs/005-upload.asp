<%
  my $file = $Request->FileUpload('filename');
  
  while( my $line = <$file> )
  {
    $Response->Write( $line );
  }# end while()
  
  close($file);
  
  $Response->End;
%>
