<%
  use Data::Dumper;
%>
<html>
<head><title>Test Page</title></head>
<body>
<form name="form1" action="/mytest" method="post">
<input type="checkbox" name="fruit" value="banana" id="banana"> <label for="banana">Banana</label> <br>
<input type="checkbox" name="fruit" value="cherry" id="cherry"> <label for="cherry">Cherry</label> <br>
<input type="checkbox" name="fruit" value="apple"  id="apple">  <label for="apple">Apple</label> <br>
<input type="checkbox" name="fruit" value="peach"  id="peach">  <label for="peach">Peach</label> <br>
<input type="text" name="result" value="<%= $Server->HTMLEncode( Dumper( $Form->{fruit} ) ) %>">
<br>
<input type="submit" value="Submit">
</form>
</body>
</html>
