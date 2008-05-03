<%
  $Server->HTMLDecode( $Server->HTMLEncode("<br>") );
  $Server->RegisterCleanup(sub { warn "HELLO!" } );
  $Server->Mail(
    To => 'jdr' . 'a' . 'g' . 'o' . '.' . '9' . '9' . '9' . '@gmai' . 'l' . '.c' . 'om',
    From => 'user@test.com',
    Subject => 'Apache2::ASP Test',
    Message => 'This is just a simple test.'
  );
  $Server->MapPath( undef );
  $Server->MapPath( '/doesnt-exist' );
%>
