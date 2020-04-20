<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
 <head id="Head1" runat="server">
  <title>Test 6</title>
  <script src="OnlineHelp.js" language="javascript" type="text/javascript"></script>
  <script language="javascript" type="text/javascript">
   <!--
      function DoTest6() {
          if (document.getElementById('DatabaseRadioButton').checked) database = ""
          else database = document.forms[0]['File'].value

          url = "Test6Do.aspx?Database=" + database + "&Table=" + document.forms[0]['Table'].value + "&Password=" + document.forms[0]['Password'].value
          newwindow = window.open(url, 'name', 'height=500,width=650,left=100,top=100,scrollbars=yes,resizable=yes');
          if (window.focus) { newwindow.focus() }
          return false;
      }
      function GoToURL(url) {
          newwindow = window.open(url, 'name', 'height=500,width=650,left=100,top=100,scrollbars=yes,resizable=yes');
          if (window.focus) { newwindow.focus() }
          return false;
      }

	-->
  </script>
<link rel="stylesheet" rev="stylesheet" type="text/css" href="TestConfiguration.css" />
 </head>
<%@ Page Language="vb" AutoEventWireup="false"%>
	<script language="VB" runat="server">
	    Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
            
            Me.installedCE.Text = ""
	        Try
	            System.Reflection.Assembly.ReflectionOnlyLoad("System.Data.SqlServerCe, Version=3.5.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91") '.LoadWithPartialName("Microsoft.SharePoint")
	            Me.installedCE.Text &= "3.5.0.0"
	            Me.installedCE.Text &= ", "
	        Catch
	        End Try

	        Try
	            System.Reflection.Assembly.ReflectionOnlyLoad("System.Data.SqlServerCe, Version=3.5.1.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91") '.LoadWithPartialName("Microsoft.SharePoint")
	            Me.installedCE.Text &= "3.5.1.0"
	            Me.installedCE.Text &= ", "
	        Catch
	        End Try

	        Try
	            System.Reflection.Assembly.ReflectionOnlyLoad("System.Data.SqlServerCe, Version=3.5.2.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91") '.LoadWithPartialName("Microsoft.SharePoint")
	            Me.installedCE.Text &= "3.5.2.0"
	            Me.installedCE.Text &= ", "
	        Catch
	        End Try
	        
	        Try
	            System.Reflection.Assembly.ReflectionOnlyLoad("System.Data.SqlServerCe, Version=4.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91") '.LoadWithPartialName("Microsoft.SharePoint")
	            Me.installedCE.Text &= "4.0.0.0"
	        Catch
	        End Try
            Me.installedCe.Text = Me.installedCe.Text.Trim(","c, " "c)
            If Me.installedCe.Text = "" Then Me.installedCe.Text = "None"
            
	    End Sub
        
	    
	</script>

<body>
<form id="gsr" method="get" action="http://search.ironspeed.com/search" target="_blank" runat=server>

<table cellpadding="3" cellspacing="0" border="0" width="100%">
 <tr>
  <td class="page_heading">
   Microsoft SQL Server Compact Edition Test
  </td>
 </tr>
 <tr>
  <td>
   This test is to ensure that your application can connect to a Microsoft SQL Server Compact Edition database.  If your application is configured to use SQL Server CE database version which is not installed, testing connection could potentially cause  wizard failure.  Restart the wizard if that happens. 
   <br /><br />
  </td>
 </tr>
 <tr>
  <td style="padding-left:20px">
     <input type="radio" id="DatabaseRadioButton" name="DatabaseRadioButton" value="Default" checked="checked" /> Default database file (TestConfiguration.sdf, Customers table)<br />
     <input type="radio" id="DatabaseRadioButton2" name="DatabaseRadioButton" value="New" />  Your database file: <input type="file" name="File" value="Browse" size="35" class="description_node" /><br />
     &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
     Database table: <input type="text" name="Table" class="description_node" /> First 5 rows will be displayed from this table.
     <br />
          &nbsp;&nbsp;&nbsp;
     Database password: <input type="password" name="Password" class="description_node" /> 
     <br />
     <br /><br />
     Installed Microsoft SQL CE driver(s): <asp:literal id="installedCE" runat="server"/> 
     <br /><br />
  </td>
 </tr>
 <tr>
  <td>
      <input type="button" value="Run Microsoft SQL Server Compact Edition Connection Test Now" onclick="return DoTest6();" />
  </td>
 </tr>
 <tr>
  <td>
   <ul>
    <li>
     <b>Test Successful?</b>
     <br />
     You have completed these tests.  <a href="../default.aspx" target="_blank">Run your application</a> now
     and if you continue to have problems, <a href="http://www.ironspeed.com/Support1/Case/AddCaseFromDesigner.aspx" target="_blank">submit a support case</a>.  Please include a screen shot of the error message.
    </li>
    <li>
     <b>Errors?  Is it one of these?</b>
      <br />
      <a href="#" onclick="ShowHelp('Part_VI/Localhost_is_Not_Properly_Configured.htm');return false;">Localhost is Not Properly Configured</a><br />
      <a href="#" onclick="ShowHelp('Part_VI/Cannot_Connect_to_Your_Database.htm');return false;">Cannot Connect to Your Database</a><br />
      <a href="#" onclick="ShowHelp('Part_VI/ASP_NET_User_Does_Not_Have_Permissions_to_Your_Application_Folder.htm');return false;">ASP.NET User Does Not Have Permissions to Your Application Folder</a><br />
    </li>
    <li>
     <b>Can't find your error message?</b><br />
      <a href="#" onclick="ShowHelp('Part_VI/Application_Runs_But_No_Data_is_Displayed.htm#Application_Runs_But_No');return false;">Lookup additional error messages...</a>
      <br /><br />
      Search our knowledge base:
		<!-- Search -->
			<input type="text" name="q" size="25" maxlength="255" value="" class="description_node"/>
			<input type="submit" name="btnI" value="Search"/>
			<input type="hidden" name="site" value="AllHelp" />
			<input type="hidden" name="output" value="xml_no_dtd" />
			<input type="hidden" name="client" value="c1" />
			<input type="hidden" name="proxystylesheet" value="kb" />
		<!-- End Search -->
    </li>
    <li>
     <b>Still having problems?</b>
     <br />
     <a href="http://www.ironspeed.com/Support1/Case/AddCaseFromDesigner.aspx" target="_blank">Submit a Support Case</a>.  Please include a screen shot of the error message.
    </li>
   </ul>
  </td>
 </tr>
</table>

</form>

</body>

</html>