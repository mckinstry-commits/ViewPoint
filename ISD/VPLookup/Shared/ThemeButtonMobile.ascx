<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Control Language="C#" AutoEventWireup="false" Codebehind="ThemeButtonMobile.ascx.cs" Inherits="VPLookup.UI.ThemeButtonMobile" %>
<%@ Register Tagprefix="Selectors" Namespace="VPLookup" Assembly="VPLookup" %>

<%@ Register Tagprefix="BaseClasses" Namespace="BaseClasses.Web.UI.WebControls" Assembly="BaseClasses" %><table cellspacing="0" cellpadding="0" border="0" onclick="clickLinkButtonText(this, event);"><tr><td class="mobileThemeButton"><asp:LinkButton CommandName="Redirect" runat="server" id="_Button" cssclass="mobileButtonLink">		
	</asp:LinkButton></td></tr></table>