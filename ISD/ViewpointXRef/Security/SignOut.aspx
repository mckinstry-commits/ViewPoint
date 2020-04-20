<%@ Page Language="C#" EnableEventValidation="false" AutoEventWireup="false" Codebehind="SignOut.aspx.cs" Culture="en-US" MasterPageFile="../Master Pages/HorizontalMenu.master" Inherits="ViewpointXRef.UI.SignOut" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Tagprefix="ViewpointXRef" TagName="ThemeButton" Src="../Shared/ThemeButton.ascx" %>

<%@ Register Tagprefix="Selectors" Namespace="ViewpointXRef" Assembly="ViewpointXRef" %>

<%@ Register Tagprefix="BaseClasses" Namespace="BaseClasses.Web.UI.WebControls" Assembly="BaseClasses" %><asp:Content id="Content" ContentPlaceHolderID="PageContent" runat="server">
     <a id="StartOfPageContent"></a>
    <div id="scrollRegion" class="scrollRegion">
          <table class="dv" cellpadding="0" cellspacing="0" border="0"><tr><td class="ms-rteThemeBackColor-3-0 dh" style="border-left: 1px solid #cccccc; border-right: 1px solid #cccccc;"><table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td class="dhel"><img src="../Images/space.gif" alt="" /></td><td class="dheci" valign="middle"><asp:CollapsiblePanelExtender id="SignOutCPExtender" runat="server" TargetControlid="SignOutCollapsibleRegion" ExpandControlID="SignOutToggleIcon" CollapseControlID="SignOutToggleIcon" ImageControlID="SignOutToggleIcon" ExpandedImage="../images/icon_panelcollapse.gif" CollapsedImage="../images/icon_panelexpand.gif" SuppressPostBack="true" />
                        <asp:ImageButton id="SignOutToggleIcon" runat="server" ToolTip="<%# GetResourceValue(&quot;Btn:ExpandCollapse&quot;, &quot;ViewpointXRef&quot;) %>" causesvalidation="False" imageurl="../images/icon_panelcollapse.gif" />
            </td><td class="dhb"><table cellpadding="0" cellspacing="0" border="0"><tr><td class="dht" valign="middle"><asp:Literal runat="server" id="DialogTitle" Text="&lt;%# GetResourceValue(&quot;Txt:SignOut&quot;, &quot;ViewpointXRef&quot;) %>">	</asp:Literal></td></tr></table>
</td><td class="dher"><img src="../Images/space.gif" alt="" /></td></tr></table>
</td></tr><tr><td class="dBody securityForm"><asp:panel id="SignOutCollapsibleRegion" runat="server"><table cellpadding="0" cellspacing="0" border="0" width="325"><tr><td><asp:Label runat="server" id="SignOutMessage" Text="&lt;%# GetResourceValue(&quot;Txt:SuccessfullySignOut&quot;, &quot;ViewpointXRef&quot;) %>">	</asp:Label><br /><br /></td></tr><tr><td align="center"><ViewpointXRef:ThemeButton runat="server" id="ForgetSignInButton" button-causesvalidation="False" button-commandname="ForgetSignInInformation" button-text="&lt;%# GetResourceValue(&quot;Btn:ForgetSignInButton&quot;, &quot;ViewpointXRef&quot;) %>" button-tooltip="&lt;%# GetResourceValue(&quot;Txt:ForgetSignInButton&quot;, &quot;ViewpointXRef&quot;) %>"></ViewpointXRef:ThemeButton></td></tr><tr><td><table cellpadding="0" cellspacing="0" border="0" style="padding-top:10px; padding-bottom:5px;" align="center"><tr><td><ViewpointXRef:ThemeButton runat="server" id="OKButton" button-causesvalidation="False" button-text="&lt;%# GetResourceValue(&quot;Btn:OK&quot;, &quot;ViewpointXRef&quot;) %>" button-tooltip="&lt;%# GetResourceValue(&quot;Btn:OK&quot;, &quot;ViewpointXRef&quot;) %>"></ViewpointXRef:ThemeButton></td><td></td></tr></table>
</td></tr><tr><td><asp:Label id="CloseWindowMessage" runat="server" Text="<%# GetResourceValue(&quot;Txt:CloseWindowMessage&quot;, &quot;ViewpointXRef&quot;) %>" />&nbsp;</td></tr></table></asp:panel>
</td></tr></table></div><div id="detailPopup" class="detailRolloverPopup" onmouseout="detailRolloverPopupClose();" onmouseover="clearTimeout(gPopupTimer);"></div>
          <div class="QDialog" id="dialog" style="display:none;">
            <iframe id="QuickPopupIframe" style="width:100%;height:100%;border:none"></iframe>
          </div>  
          <asp:ValidationSummary id="ValidationSummary1" ShowMessageBox="true" ShowSummary="false" runat="server"></asp:ValidationSummary>
</asp:Content>
          