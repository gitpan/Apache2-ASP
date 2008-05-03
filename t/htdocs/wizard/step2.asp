<%
  $Response->Write("$Form->{your_name}:$Form->{favorite_color}");
  $Request->Form('your_name');
  $Request->Form('doesnt-exist');
  $Response->End;
%>
