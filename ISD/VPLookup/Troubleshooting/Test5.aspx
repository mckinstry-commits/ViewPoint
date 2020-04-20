<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
 <head id="Head1" runat="server">
  <title>Microsoft SQL Server Connection Test</title>
  <script src="OnlineHelp.js" language="javascript" type="text/javascript"></script>
  <script language="javascript" type="text/javascript">
   <!--
	function DoTest5() {
		
		url = "Test5Do.aspx?server=" + document.forms[0]['ServerName'].value +
          		"&database="+ document.forms[0]['DatabaseName'].value +
          		"&port="+ document.forms[0]['PortNumber'].value +
          		"&user=" + document.forms[0]['UserName'].value +
          		"&password=" + document.forms[0]['Password'].value +
          		"&table=" + document.forms[0]['TableName'].value
		newwindow = window.open(url,'name','height=500,width=650,left=100,top=100,scrollbars=yes,resizable=yes');
		if (window.focus) {newwindow.focus()}
		return false;
	}
	-->
  </script>
<link rel="stylesheet" rev="stylesheet" type="text/css" href="TestConfiguration.css" />
 </head>

<body>
<form id="gsr" method="get" action="http://search.ironspeed.com/search" target="_blank" runat=server>
<table cellpadding="3" cellspacing="0" border="0" width="100%">
 <tr>
  <td class="page_heading">
   MySQL Server Connection Test
  </td>
 </tr>
 <tr>
  <td>
   This test is to ensure that your application can connect to a MySQL Server database.
   <br /><br />
   Please provide the MySQL Server name, database name, whether to use user name, password and the name of a database table.
   <br /><br />
  </td>
 </tr>
 <tr>
  <td>
   <table>
    <tr>
     <td style="text-align:right; width: 140px;">Server Name</td>
     <td style="width: 180px;"><asp:textbox id="ServerName" runat="server" Text="(local)" CssClass="description_node"/></td>
     <td style="width: 280px;">Specify (local) if using a local machine.</td>
    </tr>
    <tr>
     <td style="text-align:right">Database Name</td>
     <td><asp:textbox id="DatabaseName" runat="server" Text="Northwind" CssClass="description_node"/></td>
     <td></td>
    </tr>
    <tr>
     <td style="text-align:right">Port Number</td>
     <td><asp:textbox id="PortNumber" runat="server" Text="3306" CssClass="description_node"/></td>
     
    </tr>
    <tr>
     <td style="text-align:right">User Name</td>
     <td><asp:textbox id="UserName" runat="server" Text="sa" CssClass="description_node"/></td>
     
    </tr>
    <tr>
     <td style="text-align:right">Password</td>
     <td><asp:textbox id="Password" runat="server" TextMode="Password" CssClass="description_node"/></td>
     
    </tr>
    <tr>
     <td style="text-align:right">Database Table</td>
     <td><asp:textbox id="TableName" runat="server" Text="Products" CssClass="description_node"/></td>
     <td>(e.g., Products).  First 5 rows will be displayed from this table.</td>
    </tr>
   </table>
  </td>
 </tr>
 <tr>
  <td>
   <input type="submit" value="Run MySQL Server Connection Test Now" onclick="return DoTest5();" />
  </td>
 </tr>
</table>

<table cellpadding="3" cellspacing="0" border="0" width="600">
 <tr>
  <td>
   <ul>
    <li>
     <b>Test Successful?</b>
     <br />
     <input type="button" value="Go to Next Test" onclick="parent.location='Test6.aspx'" />
    </li>
    <li>
     <b>Errors?  Is it one of these?</b>
      <br />
      <a href="#" onclick="ShowHelp('Part_VI/Database_Permission_Settings_or_Path_Are_Not_Configured_Properly.htm');return false;">Database Permission Settings or Path Are Not Configured Properly</a><br />
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