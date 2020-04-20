<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Tagprefix="Selectors" Namespace="VPLookup" Assembly="VPLookup" %>

<%@ Control Language="C#" AutoEventWireup="false" Codebehind="HeaderMobile.ascx.cs" Inherits="VPLookup.UI.HeaderMobile" %>
<%@ Register Tagprefix="BaseClasses" Namespace="BaseClasses.Web.UI.WebControls" Assembly="BaseClasses" %><table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td>
    <table cellpadding="0" cellspacing="0" border="0" width="100%" class="mobileHeader"><tr><td><table style="width: 100%"><tr><td class="mobileHeaderLeft" colspan="2"><h4>VP Reference</h4></td><td class="mobileHeaderOptions">

    <asp:CollapsiblePanelExtender id="SettingsPanelExtenderMobile" runat="server" TargetControlid="SettingsCollapsibleRegionMobile" ExpandControlID="SettingsIconMobile" CollapseControlID="SettingsIconMobile" ImageControlID="SettingsIconMobile" ExpandedImage="../images/MobileButtonSettingsCollapse.png" CollapsedImage="../images/MobileButtonSettingsExpand.png" Collapsed="true" SuppressPostBack="true" />
    <asp:ImageButton id="SettingsIconMobile" runat="server" ToolTip="<%# GetResourceValue(&quot;Btn:Settings&quot;) %>" causesvalidation="False" imageurl="../images/MobileButtonSettingsExpand.png" />
</td><td class="mobileHeaderRight">
    <div id="dvSignIn" class="mobileThemeButton" runat="server"><asp:LinkButton runat="server" id="_SignIn" causesvalidation="False" commandname="ShowSignIn" consumers="page" cssclass="mobileButtonLink" text="" tooltip="">		
	</asp:LinkButton></div>


    </td></tr></table>
</td></tr><tr><td class="mobileBodyText"><asp:Label runat="server" id="_UserStatusLbl" cssclass="mobileSignInStatus">	</asp:Label></td></tr></table>

    </td></tr><tr><td>
    <asp:panel id="SettingsCollapsibleRegionMobile" style="display: none; overflow: hidden; height: 0px; margin: 0px;" runat="server">
    <table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td class="mobileFieldValueOnBottom"><asp:dropdownlist id="LanguageSelector" runat="server" cssclass="mobileFilterInput" AutoPostBack="true"></asp:dropdownlist></td></tr><tr><td class="mobileFieldValueOnBottom"><asp:dropdownlist id="ThemeSelector" runat="server" cssclass="mobileFilterInput" AutoPostBack="true"></asp:dropdownlist></td></tr></table>

    </asp:panel>
    </td></tr></table>