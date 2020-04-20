<%@ Register Tagprefix="ViewpointXRef" TagName="ThemeButton" Src="../Shared/ThemeButton.ascx" %>

<%@ Page Language="C#" EnableEventValidation="false" AutoEventWireup="false" Codebehind="ForgotUser.aspx.cs" Culture="en-US" MasterPageFile="../Master Pages/HorizontalMenu.master" Inherits="ViewpointXRef.UI.ForgotUser" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Tagprefix="Selectors" Namespace="ViewpointXRef" Assembly="ViewpointXRef" %>

<%@ Register Tagprefix="BaseClasses" Namespace="BaseClasses.Web.UI.WebControls" Assembly="BaseClasses" %><%@ Register TagPrefix="asp" Namespace="Recaptcha" Assembly="Recaptcha" %>
<asp:Content id="PageSection" ContentPlaceHolderID="PageContent" Runat="server">
     <a id="StartOfPageContent"></a>
    <div id="scrollRegion" class="scrollRegion">
    <asp:UpdateProgress runat="server" id="UpdatePanel1_UpdateProgress1" AssociatedUpdatePanelID="UpdatePanel1">
			<ProgressTemplate>
				<div class="ajaxUpdatePanel">
				</div>
				<div style="position:absolute; padding:30px;" class="updatingContainer">
					<img src="../Images/updating.gif" alt="Updating" />
				</div>
			</ProgressTemplate>
		</asp:UpdateProgress>
		<asp:UpdatePanel runat="server" id="UpdatePanel1" UpdateMode="Conditional">
			<ContentTemplate>
<table cellpadding="0" cellspacing="0" border="0"><tr><td><table class="dv" cellpadding="0" cellspacing="0" border="0"><tr><td class="dh"><table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td class="dhel"><img src="../Images/space.gif" alt="" /></td><td class="dhb"><table cellpadding="0" cellspacing="0" border="0"><tr><td class="dht" valign="middle"><asp:Label runat="server" id="PanelTitle" Text="&lt;%# GetResourceValue(&quot;Title:ForgotUser&quot;, &quot;ViewpointXRef&quot;) %>">	</asp:Label></td></tr></table>
</td><td class="dher"><img src="../Images/space.gif" alt="" /></td></tr></table>
</td></tr><tr><td><table class="dv" cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td class="dBody securityForm"><table cellpadding="0" cellspacing="0" border="0" class="dBody" align="center" width="100%"><tr><td style="padding-left: 8px; padding-top: 10px;  padding-bottom:10px;  padding-right:10px;"><b><asp:Label runat="server" id="ForgotUserInfoLabel" Text="&lt;%# GetResourceValue(&quot;Txt:UserEmailed&quot;, &quot;ViewpointXRef&quot;) %>">	</asp:Label> 
<asp:Label runat="server" id="ForgotUserErrorLabel" visible="False">	</asp:Label></b></td></tr><tr><td style="padding-left: 8px; padding-top: 10px;  padding-bottom:10px;"><nobr></nobr><asp:Label runat="server" id="EnterEmailLabel" Text="&lt;%# GetResourceValue(&quot;Txt:EnterEmail&quot;, &quot;ViewpointXRef&quot;) %>">	</asp:Label> 
<br /><br />
<asp:TextBox runat="server" id="Emailaddress" columns="50">	</asp:TextBox>
	<asp:RequiredFieldValidator runat="server" id="EmailaddressRequiredFieldValidator" ControlToValidate="Emailaddress" ErrorMessage="&lt;%# GetResourceValue(&quot;Val:ValueIsRequired&quot;, &quot;ViewpointXRef&quot;).Replace(&quot;{FieldName}&quot;, &quot;Emailaddress&quot;) %>" enabled="True">	</asp:RequiredFieldValidator></td></tr><tr><td style="padding-left: 8px; padding-top: 10px;  padding-bottom:10px;"><asp:Label runat="server" id="FillRecaptchaLabel" Text="&lt;%# GetResourceValue(&quot;Txt:EnterCaptcha&quot;, &quot;ViewpointXRef&quot;) %>">	</asp:Label> 
<br /><br />
<asp:RecaptchaControl ID="recaptcha" runat="server" theme="clean" PublicKey="Enter your key here" PrivateKey="Enter your key here" /></td></tr><tr><td style="padding-left:8px;padding-top:10px;padding-bottom:10px;text-align:center;"><table><tr><td style="width: 40%;">&nbsp;</td><td><ViewpointXRef:ThemeButton runat="server" id="SendButton" button-causesvalidation="True" button-commandname="ResetData" button-text="&lt;%# GetResourceValue(&quot;Btn:Send&quot;, &quot;ViewpointXRef&quot;) %>" button-tooltip="&lt;%# GetResourceValue(&quot;Btn:Send&quot;, &quot;ViewpointXRef&quot;) %>" commandname="EmailLinkButton_Command"></ViewpointXRef:ThemeButton></td><td style="width: 40%;">&nbsp;</td></tr></table>
 
</td></tr></table>
</td></tr></table>
</td></tr></table>
</td></tr></table></ContentTemplate>
</asp:UpdatePanel>
</div>
    <div id="detailPopup" class="detailRolloverPopup" onmouseout="detailRolloverPopupClose();" onmouseover="clearTimeout(gPopupTimer);"></div>
      <div class="QDialog" id="dialog" style="display:none;">
        <iframe id="QuickPopupIframe" style="width:100%;height:100%;border:none"></iframe>
      </div>  
    <asp:ValidationSummary id="ValidationSummary1" ShowMessageBox="true" ShowSummary="false" runat="server"></asp:ValidationSummary>
</asp:Content>