﻿<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Control Language="C#" AutoEventWireup="false" Codebehind="ThemeButton.ascx.cs" Inherits="ViewpointXRef.UI.ThemeButton" %>
<%@ Register Tagprefix="Selectors" Namespace="ViewpointXRef" Assembly="ViewpointXRef" %>

<%@ Register Tagprefix="BaseClasses" Namespace="BaseClasses.Web.UI.WebControls" Assembly="BaseClasses" %><table class="buttonPadding" cellspacing="0" cellpadding="0" border="0" onmouseover="this.style.cursor='pointer'; return true;" onclick="clickLinkButtonText(this, event);"><tr><td class="bTL"><img src="../Images/space.gif" alt="" class="bTLSpace" /></td><td class="bT"><img src="../Images/space.gif" alt="" class="bTSpace" /></td><td class="bTR"><img src="../Images/space.gif" alt="" class="bTRSpace" /></td></tr><tr><td class="bL"><img src="../Images/space.gif" alt="" class="bLSpace" /></td><td class="bC"><asp:LinkButton CommandName="Redirect" runat="server" id="_Button" cssclass="button_link">		
	</asp:LinkButton></td><td class="bR"><img src="../Images/space.gif" alt="" class="bRSpace" /></td></tr><tr><td class="bBL"><img src="../Images/space.gif" alt="" class="bBLSpace" /></td><td class="bB"><img src="../Images/space.gif" alt="" class="bBSpace" /></td><td class="bBR"><img src="../Images/space.gif" alt="" class="bBRSpace" /></td></tr></table>