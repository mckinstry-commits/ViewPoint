<%@ Page Language="c#" AutoEventWireup="true" EnableEventValidation="false" Codebehind="ForbiddenMobile.aspx.cs" Inherits="POViewer.UI.ForbiddenMobile" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
<title>Forbidden</title>
</head>
<body style="margin: 0px; padding: 0px;">
<table cellspacing="0" cellpadding="0" border="0" class="mobileBase">
  <tr>
  <td class="mobileHeader">
    <table cellspacing="0" cellpadding="0" border="0" style="width: 100%;">
      <tr>
                        <td class="mobileHeaderLeft">&nbsp;</td>
                        <td class="mobileHeaderTitle" style="padding-top: 0px;">Forbidden</td>
                        <td class="mobileHeaderOption">&nbsp;</td>
                        <td class="mobileHeaderRight">&nbsp;</td>
      </tr>
    </table>
  </td>
  </tr>
  <tr>
  <td class="mobileBody">
<br />
				<asp:Literal id="ForbiddenText1" runat="server" Text='<%# GetResourceValue("Txt:ForbiddenLine1") %>'/><br /><br /> 
				<asp:Literal id="ForbiddenText2" runat="server" Text='<%# GetResourceValue("Txt:ForbiddenLine2") %>'/><br /><br /> 
  </td>
  </tr>
</table>
</body>
</html>
