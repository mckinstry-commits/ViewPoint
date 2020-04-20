<%@ Register Tagprefix="VPLookup" TagName="HeaderMobile" Src="../Header and Footer/HeaderMobile.ascx" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Tagprefix="VPLookup" TagName="MenuMobile" Src="../Menu Panels/MenuMobile.ascx" %>

<%@ Register Tagprefix="VPLookup" TagName="FooterMobile" Src="../Header and Footer/FooterMobile.ascx" %>

<%@ Register Tagprefix="BaseClasses" Namespace="BaseClasses.Web.UI.WebControls" Assembly="BaseClasses" %>
<%@ Register Tagprefix="Selectors" Namespace="VPLookup" Assembly="VPLookup" %>

<%@ Page Language="C#" EnableEventValidation="false" AutoEventWireup="false" Codebehind="StartMobile.aspx.cs" Culture="en-US" MasterPageFile="" Inherits="VPLookup.UI.StartMobile" %><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
    <head id="Head1" runat="server">
    <meta name="keywords" content="VPLookup" />
    <title></title>
    </head>
    <body id="Body1" runat="server" style="margin: 0px; padding: 0px;">
        <form id="Form1" method="post" runat="server">
            <BaseClasses:ScrollCoordinates id="ScrollCoordinates1" runat="server"></BaseClasses:ScrollCoordinates>
            <BaseClasses:BasePageSettings id="PageSettings" runat="server"></BaseClasses:BasePageSettings>
            <script language="JavaScript" type="text/javascript">clearRTL()</script>
            <asp:ToolkitScriptManager ID="scriptManager1" runat="server" EnablePartialRendering="True" EnablePageMethods="True" EnableScriptGlobalization="True" EnableScriptLocalization="True">
			</asp:ToolkitScriptManager>
          <table cellpadding="0" cellspacing="0" border="0" width="100%" class="mobileBase"><tr><td><a id="StartOfPageContent"></a><VPLookup:HeaderMobile runat="server" id="PageHeader"></VPLookup:HeaderMobile></td></tr><tr><td class=""></td></tr><tr><td><VPLookup:MenuMobile runat="server" id="MenuV" hilitesettings=""></VPLookup:MenuMobile></td></tr><tr><td><VPLookup:FooterMobile runat="server" id="PageFooter"></VPLookup:FooterMobile></td></tr><tr><td><div id="detailPopup" class="detailRolloverPopup" onmouseout="detailRolloverPopupClose();" onmouseover="clearTimeout(gPopupTimer);"></div>          
        <asp:ValidationSummary id="ValidationSummary1" ShowMessageBox="true" ShowSummary="false" runat="server"></asp:ValidationSummary>
    
          </td></tr></table>
        </form>
    </body>
</html>
          