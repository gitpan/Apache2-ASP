
package Apache2::ASP::Manual::Intro;

1;

__END__

=pod

=head1 NAME

Apache2::ASP - ASP for a mod_perl2 environment.

=head1 SYNOPSIS

  <html>
    <body>
      <%= "Hello, World!" %>
      <br>
      <%
        for( 1...10 ) {
          $Response->Write( "Hello from ASP ($_)<br>" );
        }
      %>
    </body>
  </html>

=head1 DESCRIPTION

Apache2::ASP is a new implementation of the ASP web programming for the mod_perl2 
environment.  Its aim is high performance, stability, scalability and ease of use.

If you have used L<Apache::ASP> already then you are already familiar with the basic
idea of ASP under Apache.

=head1 INTRODUCTION

=head2 What is Apache2::ASP?

Apache2::ASP is a web programming environment that helps simplify 
web programming with Perl under mod_perl2.  Apache2::ASP allows 
you to easily embed Perl into web pages using the "<%" and "%>"
tags that are familiar to anyone who has used ASP or JSP in the past.

=head2 What does Apache2::ASP offer?

Apache2::ASP offers programmers the ability to program web pages without
spending time on details like session state management, file uploads
or template systems.

=head1 ASP OBJECTS

Like other ASP web programming environments, Apache2::ASP provides the
following global objects:

=head2 $Request

Represents the incoming HTTP request.  Has methods to handle form data,
file uploads, read cookies, etc.

Learn more by reading the L<Apache2::ASP::Request> documentation.

=head2 $Form

The same as $Request->Form, it is a hashref of all incoming form and querystring values.

=head2 $Response

Represents the outbound HTTP communication to the client.  Has methods to
send content, redirect, set cookies, etc.

Learn more by reading the L<Apache2::ASP::Response> documentation.

=head2 $Session

Represents data that should persist beyond the lifetime of a single request.
For example, the user's logged in state, user id, etc.

The contents of the C<$Session> object are stored within an SQL database.

Learn more by reading the L<Apache2::ASP::Session> documentation.

=head2 $Server

Represents the webserver itself and offers several utility methods that don't
fit anywhere else.

Learn more by reading the L<Apache2::ASP::Server> documentation.

=head2 $Application

Represents data that should be shared and persisted throughout the entire 
web application.  For example, database connection strings, the number of active
users, etc.

The contents of the C<$Application> object are stored within an SQL database.

Learn more by reading the L<Apache2::ASP::Application> documentation.

=head2 $Config

Encapsulates all the configuration information for your web application.

Learn more by reading the L<Apache2::ASP::Config> documentation.

=head1 INSTALLATION

  % perl Makefile.PL
  % make
  % make test
  % make install

Then, in your httpd.conf:
  
  # Needed for CGI::Apache2::Wrapper to work properly:
  LoadModule apreq_module    /usr/local/apache2/modules/mod_apreq2.so
  
  # Set the directory index:
  DirectoryIndex index.asp
  
  # Set this variable:
  PerlSetEnv APACHE2_ASP_APPLICATION_ROOT /path/to/your/web/application
  
  # Load up some important modules:
  PerlModule Apache::DBI
  PerlModule DBI
  PerlModule DBD::mysql
  PerlModule Apache2::ASP
  PerlModule Apache2::ASP::PostConfigHandler
  PerlPostConfigHandler Apache2::ASP::PostConfigHandler
  
  # Configuration for MediaManager:
  PerlModule        Apache2::ASP::TransHandler
  PerlTransHandler  Apache2::ASP::TransHandler
  
  # All *.asp files are handled by Apache2::ASP
  <Files ~ (\.asp$)>
    SetHandler  perl-script
    PerlHandler Apache2::ASP
  </Files>
  
  # Prevent anyone from getting your GlobalASA.pm
  <Files ~ (\.pm$)>
    Order allow,deny
    Deny from all
  </Files>
  
  # All requests to /handlers/* will be handled by their respective handler:
  <Location /handlers>
    SetHandler  perl-script
    PerlHandler Apache2::ASP
  </Location>
  
  # Main website:
  <VirtualHost *:80>
    ServerName    yoursite.yourhost.com
    DocumentRoot  /path/to/your/web/application/htdocs
  </VirtualHost>

Then create a directory at C</path/to/your/website/PAGE_CACHE> at the root of your application.  The Apache server process
should be able to read and write in this directory.

Then, in C</path/to/your/website/conf> add the file C<apache2-asp-config.xml>.
It will contain data like this:

  <?xml version="1.0" ?>
  <config>
    <web_application>
      <domain_re>^.*my\-website\.com$</domain_re>
      <do_reload_on_script_change>1</do_reload_on_script_change>
      <application_name>DefaultApp</application_name>
      <application_root>@ServerRoot@</application_root>
      <handler_root>@ServerRoot@/handlers</handler_root>
      <media_manager_upload_root>@ServerRoot@/MEDIA</media_manager_upload_root>
      <www_root>@ServerRoot@/htdocs</www_root>
      <page_cache_root>@ServerRoot@/PAGE_CACHE</page_cache_root>
      <application_state>
        <manager>Apache2::ASP::ApplicationStateManager::SQLite</manager>
        <dsn>DBI:SQLite:dbname=/tmp/apache2_asp_state</dsn>
        <password></password>
        <username></username>
      </application_state>
      <session_state>
        <manager>Apache2::ASP::SessionStateManager::SQLite</manager>
        <cookie_domain>localhost</cookie_domain>
        <cookie_name>session-id</cookie_name>
        <dsn>DBI:SQLite:dbname=/tmp/apache2_asp_state</dsn>
        <password></password>
        <username></username>
        <session_timeout>30</session_timeout>
      </session_state>
    </web_application>
    <!-- You can specify more web_application elements below. -->
  </config>

Then, in your database, create a table with the following structure:

  CREATE TABLE asp_sessions (
    session_id CHAR(32) PRIMARY KEY NOT NULL,
    session_data BLOB,
    created_on DATETIME,
    modified_on DATETIME
  );

Also create a table with the following structure:

  CREATE TABLE asp_applications (
    application_id VARCHAR(100) PRIMARY KEY NOT NULL,
    application_data BLOB
  );

Simply restart Apache and installation is complete.  Now you need some ASP scripts.

If your website is in C</var/www/html> then create a file "C<index.asp>" in C</var/www/html>.

Your C<index.asp> could contain something like the following:

  <html>
    <body>
      <%= "Hello, World!" %>
      <br>
      <%
        for( 1...10 ) {
          $Response->Write( "Hello from ASP ($_)<br>" );
        }
      %>
    </body>
  </html>

Then point your browser to C<http://yoursite.com/index.asp> and see what you get.

If everything was configured correctly, the output would look like:

  Hello, World! 
  Hello from ASP (1)
  Hello from ASP (2)
  Hello from ASP (3)
  Hello from ASP (4)
  Hello from ASP (5)
  Hello from ASP (6)
  Hello from ASP (7)
  Hello from ASP (8)
  Hello from ASP (9)
  Hello from ASP (10)

If you get an error instead, check out your error log to find out why.

=head2 Directory Structure

You might be wondering, "What does the directory structure for an Apache2::ASP website look like?"

Well, it looks like this:

  .
  |-- conf (+r)
  |   |-- apache2-asp-config.xml
  |   `-- httpd.conf
  |-- etc (+r)
  |   |-- other_files_needed_by_the_site.txt
  |   `-- giant_word_dictionary.txt
  |-- MEDIA (+rw)
  |-- PAGE_CACHE (+rw)
  |--handlers (+r)
  |  |--MyHandler.pm
  |  `--MyOtherHandler.pm
  `-- www (+r)
      |-- GlobalASA.pm
      `-- index.asp

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-ASP> to submit bug reports.

=head1 HOMEPAGE

Please visit the Apache2::ASP homepage at L<http://apache2-asp.no-ip.org/> to see examples
of Apache2::ASP in action.

=head1 AUTHOR

John Drago L<mailto:jdrago_999@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 John Drago, All rights reserved.

This software is free software.  It may be used and distributed under the
same terms as Perl itself.

=cut

