<html>
<body>
  <form method="POST" enctype="multipart/form-data" action="/handlers/MediaManager">
    <!-- This "mode" parameter tells us what we're going to do -->
    <!-- Possible values include "create", "update" and "delete" -->
    <input type="hidden" name="mode" value="create">
    <input type="file" name="filename">
    <input type="submit" value="Click Here to Upload">
  </form>
</body>
</html>
