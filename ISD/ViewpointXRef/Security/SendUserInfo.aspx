<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Tagprefix="BaseClasses" Namespace="BaseClasses.Web.UI.WebControls" Assembly="BaseClasses" %>
<%@ Register Tagprefix="Selectors" Namespace="ViewpointXRef" Assembly="ViewpointXRef" %>

<%@ Page Language="C#" EnableEventValidation="false" AutoEventWireup="false" Codebehind="SendUserInfo.aspx.cs" Culture="en-US" MasterPageFile="../Master Pages/Email.master" Inherits="ViewpointXRef.UI.SendUserInfo" %><asp:Content id="PageSection" ContentPlaceHolderID="PageContent" Runat="server">
    <a id="StartOfPageContent"></a>
    
                <table cellpadding="20" cellspacing="0" border="0"><tr><td colspan="2" style="color: #555555; font-family: Verdana, Arial, Georgia, sans-serif; font-size: 12px; padding-bottom: 0px; padding-left: 4px; padding-right: 4px; padding-top: 8px; text-align: left; vertical-align: top;"><asp:Label runat="server" id="InformationLabel" Text="&lt;%# GetResourceValue(&quot;Txt:HereisSignin&quot;, &quot;ViewpointXRef&quot;) %>">	</asp:Label></td></tr><tr><td><asp:Literal runat="server" id="MyLoginInfo" Text="Username Password">	</asp:Literal></td><td class="dfv"></td></tr></table>
    
    <div id="detailPopup" class="detailRolloverPopup" onmouseout="detailRolloverPopupClose();" onmouseover="clearTimeout(gPopupTimer);"></div>
        <div class="QDialog" id="dialog" style="display:none;">
          <iframe id="QuickPopupIframe" style="width:100%;height:100%;border:none"></iframe>
        </div>  
    <asp:ValidationSummary id="ValidationSummary1" ShowMessageBox="true" ShowSummary="false" runat="server"></asp:ValidationSummary>
</asp:Content>
                