
The Troubleshooting folder in your application contains a number of web pages 
that test various aspects of your configuration to make sure that everything 
is working correctly.


PURPOSE:

These tests use generic Microsoft .NET Framework code.  No Iron Speed Designer
specific code is used in these tests.  A test that fails generally indicates a
configuration problem with your system.


DELETE AFTER DEPLOYMENT:

Once your application has been tested and deployed, this folder can be deleted 
in its entirety without any problems.  No part of your application is dependent
on any files in this folder.


TESTS INCLUDED:

The following tests are included in the system.

Test0: Microsoft .NET Framework Installation Test
Calls Response.Write ASPX function to test if a basic ASPX page can be
displayed.  If this test fails then most likely Microsoft .NET Framework is not
installed or not configured properly.

Test1: Microsoft .NET Framework Configuration Test
A more advanced Microsoft .NET Framework test.  This test prints out
a number of server variables indicating the version of Microsoft .NET Framework,
the version of the browser, etc.  If this test fails, then most likely 
Microsoft .NET Framework is not installed or not configured properly.

Test2: Microsoft Access Connection Test
This test checks to see if the Microsoft Access database can be properly
accessed and used by your application.  If this test fails, then it could be
because (1) the virtual directory has not been created; (2) the user account
under which your application is running does not have read/write access to the 
Microsoft Access database file or folder; or (3) the user account does not
have read/write access to the temporary folder of your Windows server.

Test3: Microsoft SQL Server Connection Test
This test checks to see if you can access the Microsoft SQL Server database.
If this test fails, then it could be because (1) you are using Windows Authentication
in Impersonate mode and the SQL Server and is located on a different machine 
(double hops are not allowed); (2) you are using Windows Authentication
in Impersonate mode and the user connecting to the application does not have
access to the SQL Server; (3) you are using SQL Server authentication and your
server does not recognize the user name and password.

Test4: Oracle Connection Test
This test is to ensure that your application can connect to an Oracle database.
If this test fails, then it could be because 
(1) OraOLEDB.Oracle provider is not registered;
(2) your computer requires Oracle client software version 8.1.7 or greater;
(3) ORA-12154: TNS:could not resolve service name. The connection identifier 
you specified could not be resolved into a connect descriptor using one of the 
naming methods configured. For example, if the type of connect identifier used 
was a net service name then the net service name could not be found in a naming 
method repository, or the repository could not be located or reached. See: 
http://ora-12154.ora-code.com/

Test5: MySQL Server Connection Test  
This test is to ensure that your application can connect to a Microsoft MySQL Server database. 
If this test fails, then it could be because 
(1) Localhost is Not Properly Configured;
(2) Cannot Connect to Your Database
(3) ASP.NET User Does Not Have Permissions to Your Application Folder

Test6: Microsoft SQL Server Compact Edition Test
This test is to ensure that your application can connect to a Microsoft SQL Server Compact Edition database. 
If this test fails, then it could be because 
(1) Database Permission Settings or Path Are Not Configured Properly;
(2) Localhost is Not Properly Configured;
(3) Cannot Connect to Your Database;
(4) ASP.NET User Does Not Have Permissions to Your Application Folder.
If your application is configured to use an SQL Server CE database version 
which is not installed, testing the connection could potentially cause 
the wizard to fail. Restart the wizard if that happens. 

In all of these cases, you can search the Knowledge Base with the text of
the error message to find a solution to the problem.  The knowledge base is
available at http://www.ironspeed.com/kb.

Updated: 9/21/2013
