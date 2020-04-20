<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Tagprefix="Selectors" Namespace="ViewpointXRef" Assembly="ViewpointXRef" %>

<%@ Control Language="C#" AutoEventWireup="false" Codebehind="Menu_ItemVertical.ascx.cs" Inherits="ViewpointXRef.UI.Menu_ItemVertical" %>
<%@ Register Tagprefix="BaseClasses" Namespace="BaseClasses.Web.UI.WebControls" Assembly="BaseClasses" %><table cellspacing="0" cellpadding="0" border="0" onmouseover="this.style.cursor='pointer'; return true;" onclick="clickLinkButtonText(this, event);" width="100%"><tr><td class="ms-rteImage-4"><asp:LinkButton CommandName="Redirect" runat="server" id="_Button" cssclass="menu">		
	</asp:LinkButton></td></tr></table>