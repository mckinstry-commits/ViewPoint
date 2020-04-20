<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
 <head id="Head1" runat="server">
  <title>Run Microsoft .NET Framework (Basic) Test</title>
  <script src="OnlineHelp.js" language="javascript" type="text/javascript"></script>

  <script language="javascript" type="text/javascript">
   <!--
	function DoTest() {
		url = "Test0Do.aspx"
		newwindow = window.open(url,'name','height=500,width=650,left=100,top=100,scrollbars=yes,resizable=yes');
		if (window.focus) {newwindow.focus()}
		return false;
	}
	-->
  </script>
<link rel="stylesheet" rev="stylesheet" type="text/css" href="TestConfiguration.css" />
 </head>

<body>

<form id="gsr" method="get" action="http://search.ironspeed.com/search" target="_blank">

<table cellpadding="3" cellspacing="0" border="0" width="100%">
 <tr>
  <td class="page_heading">
   Microsoft .NET Framework Installation Test
  </td>
 </tr>
 <tr>
  <td>
  Run this test to see if you have Microsoft .NET Framework installed.
   <br /><br />
  </td>
 </tr>
 <tr>
  <td>
   <input type="button" value="Run Microsoft .NET Framework Installation Test Now" onclick="return DoTest();" />
  </td>
 </tr>
 <tr>
  <td>
   <ul>
    <li>
     <b>Test Successful?</b>
     <br />
     <input type="button" value="Go to Next Test" onclick="parent.location='Test1.aspx'" />
    </li>
    <li>
     <b>Errors?  Is it one of these?</b>
      <br />
      <a href="#" onclick="ShowHelp('Part_VI/ASPX_HTML_is_Displayed_Instead_of_Your_Application.htm');return false;">ASPX (HTML) is Displayed Instead of Your Application</a><br />
      <a href="#" onclick="ShowHelp('Part_VI/Parser_Error_Unrecognized_attribute_validateRequest.htm');return false;">Configuration Error: Unrecognized attribute 'validateRequest'...</a><br />
      <a href="#" onclick="ShowHelp('Part_VI/HTTP_Error_403_-_Forbidden_You_are_not_authorized_to_view_this_page.htm');return false;">HTTP Error 403 - Forbidden.  You are not authorized to view this page...</a><br />
      <a href="#" onclick="ShowHelp('Part_VI/HTTP_Error_404_-_Page_Not_Found.htm');return false;">HTTP Error 404 - Page Not Found</a><br />
      <a href="#" onclick="ShowHelp('Part_VI/HTTP_Error_500_-_Page_Cannot_be_Displayed.htm');return false;">HTTP Error 500 - Page cannot be displayed...</a><br />
    </li>
    <li>
     <b>Can't find your error message?</b><br />
      <a href="#" onclick="ShowHelp('Part_VI/Application_Error_Messages.htm#Application_Error');return false;">Lookup additional error messages...</a>
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