<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Tagprefix="Selectors" Namespace="POViewer" Assembly="POViewer" %>

<%@ Register Tagprefix="BaseClasses" Namespace="BaseClasses.Web.UI.WebControls" Assembly="BaseClasses" %>
<%@ Control Language="C#" AutoEventWireup="false" Codebehind="ThemeButtonMobile.ascx.cs" Inherits="POViewer.UI.ThemeButtonMobile" %><table cellspacing="0" cellpadding="0" border="0" onclick="clickLinkButtonText(this, event);"><tr><td class="mobileThemeButton"><asp:LinkButton CommandName="Redirect" runat="server" id="_Button" cssclass="mobileButtonLink">		
	</asp:LinkButton></td></tr></table>