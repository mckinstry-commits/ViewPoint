﻿<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Page Language="C#" EnableEventValidation="false" AutoEventWireup="false" Codebehind="SignOutMobile.aspx.cs" Culture="en-US" MasterPageFile="../Master Pages/Mobile.master" Inherits="ViewpointXRef.UI.SignOutMobile" %>
<%@ Register Tagprefix="ViewpointXRef" TagName="ThemeButtonMobile" Src="../Shared/ThemeButtonMobile.ascx" %>

<%@ Register Tagprefix="Selectors" Namespace="ViewpointXRef" Assembly="ViewpointXRef" %>

<%@ Register Tagprefix="BaseClasses" Namespace="BaseClasses.Web.UI.WebControls" Assembly="BaseClasses" %><asp:Content id="Content" ContentPlaceHolderID="PageContent" runat="server">
    <a id="StartOfPageContent"></a>
          <table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td><table cellpadding="0" cellspacing="0" border="0" width="100%" class="mobileHeader"><tr><td class="mobileHeaderLeft"><ViewpointXRef:ThemeButtonMobile runat="server" id="MenuButton" button-causesvalidation="False" button-commandname="Redirect" button-text="&lt;%# GetResourceValue(&quot;Btn:Menu&quot;, &quot;ViewpointXRef&quot;) %>" button-tooltip="&lt;%# GetResourceValue(&quot;Btn:Menu&quot;, &quot;ViewpointXRef&quot;) %>" postback="False"></ViewpointXRef:ThemeButtonMobile></td><td class="mobileHeaderTitle"><asp:Literal runat="server" id="DialogTitle" Text="&lt;%# GetResourceValue(&quot;Txt:SignOut&quot;, &quot;ViewpointXRef&quot;) %>">	</asp:Literal></td><td class="mobileHeaderRight"></td></tr></table>
</td></tr><tr><td class="mobileBody"><asp:panel id="SignOutCollapsibleRegion" runat="server"><table cellpadding="0" cellspacing="0" border="0" width="100%" class="mobileBody"><tr><td class="mobileBodyText"><asp:Label runat="server" id="SignOutMessage" Text="&lt;%# GetResourceValue(&quot;Txt:SuccessfullySignOut&quot;, &quot;ViewpointXRef&quot;) %>">	</asp:Label><br /><br /></td></tr><tr><td><ViewpointXRef:ThemeButtonMobile runat="server" id="ForgetSignInButton" button-causesvalidation="False" button-commandname="ForgetSignInInformation" button-text="&lt;%# GetResourceValue(&quot;Btn:ForgetSignInButton&quot;, &quot;ViewpointXRef&quot;) %>" button-tooltip="&lt;%# GetResourceValue(&quot;Btn:ForgetSignInButton&quot;, &quot;ViewpointXRef&quot;) %>"></ViewpointXRef:ThemeButtonMobile></td></tr><tr><td class="mobileBodyText"><br /><asp:Label id="CloseWindowMessage" runat="server" Text="<%# GetResourceValue(&quot;Txt:CloseWindowMessage&quot;, &quot;ViewpointXRef&quot;) %>" />&nbsp;</td></tr></table></asp:panel>
</td></tr></table><div id="detailPopup" class="detailRolloverPopup" onmouseout="detailRolloverPopupClose();" onmouseover="clearTimeout(gPopupTimer);"></div>          
        <asp:ValidationSummary id="ValidationSummary1" ShowMessageBox="true" ShowSummary="false" runat="server"></asp:ValidationSummary>
    </asp:Content>
          