<!--
Test Failed.

We tested whether you can execute a very simple ASPX page containing
a Response.Write statement.

If you see this text displayed in your browser window, it means that
this test has failed.  Go back to the previous window and look at
possible fixes for this problem.
-->
<%@ Page Language="cs" AutoEventWireup="false"  Debug="true" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
 <head id="Head1" runat="server">
  <title>Run ASPX Test Results</title>
  <script src="OnlineHelp.js" language="javascript" type="text/javascript"></script>
  <link rel="stylesheet" rev="stylesheet" type="text/css" href="TestConfiguration.css" />
 </head>

<body>

<table cellpadding="3" cellspacing="0" border="0" width="100%">
 <tr>
  <td>
  <%
   Response.Write("Testing Microsoft .NET Framework...");
  %>
  <br /><br />
  </td>
 </tr>
 <tr>
  <td class="page_heading">
  <%
   if (Request.Browser.Type.StartsWith("IE") || Request.Browser.Type.ToLower().StartsWith("internetexplorer")) {
   	   // Internet Explorer
	   if ((System.Environment.Version.ToString().StartsWith("2.0.50727") 
	        || System.Environment.Version.ToString().StartsWith("3.0.4506") 
	        || System.Environment.Version.ToString().StartsWith("3.5.21022") 
	        || System.Environment.Version.ToString().StartsWith("3.5.30729") 
	        || System.Environment.Version.ToString().StartsWith("4.0.30319")) &&
		  ((Request.Browser.MajorVersion >= 5 && Request.Browser.MinorVersion >= 5) ||
		   Request.Browser.MajorVersion >= 6)) {
		   Response.Write("Test Successful!");
		    //Response.Write("<br /><br />The primary version of the Microsoft .NET Framework installed on your system is " +
			//		System.Environment.Version.ToString());
	   } else {
	       Response.Write("<span class=\"description_node\">");
		   Response.Write("<font color=\"red\"><b>Test Failed.</b></font><br /><br />");
		   if (!System.Environment.Version.ToString().StartsWith("2.0.50727") 
		        && !System.Environment.Version.ToString().StartsWith("3.0.4506") 
		        && !System.Environment.Version.ToString().StartsWith("3.5.21022") 
		        && !System.Environment.Version.ToString().StartsWith("3.5.30729") 
		        && !System.Environment.Version.ToString().StartsWith("4.0.30319") ) {
			   Response.Write("The primary version of the Microsoft .NET Framework installed on your system is " +
					System.Environment.Version.ToString() +
					".<br /><br />Applications created with Iron Speed Designer currently require either " +
					"Microsoft .NET Framework 2.0 (2.0.50727), or<br />" +
					"Microsoft .NET Framework 3.0 (3.0.4506), or<br />" +
					"Microsoft .NET Framework 3.5 (3.5.21022), or<br />" +
					"Microsoft .NET Framework 3.5 (3.5.30729), or<br />" +
					"Microsoft .NET Framework 4.0 (4.0.30319).");
		   }
		   if (!((Request.Browser.MajorVersion >= 5 && Request.Browser.MinorVersion >= 5) ||
				 Request.Browser.MajorVersion >= 6)) {
				Response.Write("The version of the browser you are using is." + Request.Browser.Version + "<br />");
		   }
		   Response.Write("</span>");
	   }
	} else {
		// Firefox, Netscape or some other browser.
		Response.Write("Test Successful!");
        Response.Write("<br /><br /><span class=\"description_node\">");
        Response.Write("It seems you are using a browser other than Microsoft Internet Explorer.<br />");
        Response.Write("It seems you can run .NET applications, but we could not test your specific version of Microsoft .NET Framework.<br />");
        Response.Write("If you encounter problems, please try the Version Check utility on the previous page.<br />");
  	    Response.Write("</span>");

	}
  %>
  <br /><br />
  </td>
 </tr>
 <tr>
  <td>
	.NET Framework Version (Client): <%=System.Environment.Version%>
	<br />
	Browser Version: <%=Request.Browser.Version%>
	<br />
	Operating System: <%=Request.Browser.Platform%>
	<br />
	Browser String: <%=Request.ServerVariables["http_user_agent"]%>
	<br />
	Browser Language: <%=Request.ServerVariables["http_accept_language"]%>
	<br />
	Browser Type: <%=Request.Browser.Type %>
	<br />
	Browser Beta: <%=Request.Browser.Beta%>
	<br />
	Supports ActiveX controls: <%=Request.Browser.ActiveXControls %>
	<br />
	Supports Cookies: <%=Request.Browser.Cookies%>
	<br />
	Supports Frames: <%=Request.Browser.Frames%>
	<br />
	Supports HTML Tables: <%=Request.Browser.Tables%>
	<br />
	Supports Java Applets: <%=Request.Browser.JavaApplets%>
	<br />
	Supports Java Scripts: <%=Request.Browser.EcmaScriptVersion%>
	<br />
	Supports MS DOM Version: <%=Request.Browser.MSDomVersion%>
	<br /><br />
  </td>
 </tr>
 <tr>
  <td>
	<input type="button" value="Close Window" onclick="javascript:window.close();" />
  </td>
 </tr>
</table>

</body>

</html>