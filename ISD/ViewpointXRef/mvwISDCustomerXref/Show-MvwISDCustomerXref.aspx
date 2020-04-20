<%@ Register Tagprefix="ViewpointXRef" TagName="ThemeButton" Src="../Shared/ThemeButton.ascx" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Page Language="C#" EnableEventValidation="false" AutoEventWireup="false" Codebehind="Show-MvwISDCustomerXref.aspx.cs" Culture="en-US" MasterPageFile="../Master Pages/HorizontalMenu.master" Inherits="ViewpointXRef.UI.Show_MvwISDCustomerXref" %>
<%@ Register Tagprefix="ViewpointXRef" Namespace="ViewpointXRef.UI.Controls.Show_MvwISDCustomerXref" Assembly="ViewpointXRef" %>

<%@ Register Tagprefix="Selectors" Namespace="ViewpointXRef" Assembly="ViewpointXRef" %>

<%@ Register Tagprefix="BaseClasses" Namespace="BaseClasses.Web.UI.WebControls" Assembly="BaseClasses" %><asp:Content id="PageSection" ContentPlaceHolderID="PageContent" Runat="server">
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

                <table cellpadding="0" cellspacing="0" border="0"><tr><td><%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("CancelButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("EditButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("OKButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("SaveAndNewButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("SaveButton"))%>

                        <ViewpointXRef:MvwISDCustomerXrefRecordControl runat="server" id="MvwISDCustomerXrefRecordControl">	<table class="dv" cellpadding="0" cellspacing="0" border="0"><tr><td class="ms-rteThemeBackColor-3-0 dh"><table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td><img src="../Images/space.gif" alt="" /></td><td><table cellpadding="0" cellspacing="0" border="0"><tr><td><asp:Literal runat="server" id="Title" Text="&lt;%#String.Concat(&quot;Customer Cross Reference&quot;) %>">	</asp:Literal></td><td class="dhir"><asp:ImageButton runat="server" id="DialogEditButton" causesvalidation="False" commandname="Redirect" imageurl="../Images/iconEdit.gif" onmouseout="this.src='../Images/iconEdit.gif'" onmouseover="this.src='../Images/iconEditOver.gif'" tooltip="&lt;%# GetResourceValue(&quot;Btn:Edit&quot;, &quot;ViewpointXRef&quot;) %>" visible="False">		
	</asp:ImageButton></td></tr></table>
</td><td><img src="../Images/space.gif" alt="" /></td></tr></table>
</td></tr><tr><td><asp:panel id="CollapsibleRegion" runat="server"><table class="dBody" cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td><asp:panel id="MvwISDCustomerXrefRecordControlPanel" runat="server"><table cellpadding="0" cellspacing="0" border="0"><tr><td class="fls"><asp:Literal runat="server" id="VPCustomerLabel" Text="VP Customer">	</asp:Literal></td><td class="dfv"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="VPCustomer"></asp:Literal></span>
 </td><td class="fls"><asp:Literal runat="server" id="CustGroupLabel" Text="Customer Group">	</asp:Literal></td><td class="fls"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="CustGroup"></asp:Literal></span>
</td></tr><tr><td class="fls"><asp:Literal runat="server" id="CGCCustomerLabel" Text="CGC Customer">	</asp:Literal></td><td class="dfv"><asp:Literal runat="server" id="CGCCustomer"></asp:Literal></td><td class="fls"><asp:Literal runat="server" id="AsteaCustomerLabel" Text="Astea Customer">	</asp:Literal></td><td class="dfv"><asp:Literal runat="server" id="AsteaCustomer"></asp:Literal></td></tr><tr><td class="fls"><asp:Literal runat="server" id="CustomerNameLabel" Text="Customer Name">	</asp:Literal></td><td class="dfv" colspan="3"><asp:Literal runat="server" id="CustomerName"></asp:Literal></td></tr><tr><td class="fls"><asp:Literal runat="server" id="AddressLabel" Text="Address">	</asp:Literal></td><td class="dfv" colspan="3"><asp:Literal runat="server" id="Address"></asp:Literal> <br />
<asp:Literal runat="server" id="Address2"></asp:Literal> <br />
<asp:Literal runat="server" id="City"></asp:Literal> ,
<asp:Literal runat="server" id="State"></asp:Literal> 
<asp:Literal runat="server" id="Zip"></asp:Literal></td></tr><tr><td class="fls"><asp:Literal runat="server" id="CustomerKeyLabel" Text="Customer Key" visible="False">	</asp:Literal></td><td class="dfv"><asp:Literal runat="server" id="CustomerKey" visible="False"></asp:Literal></td><td class="fls"></td><td class="dfv"></td></tr></table></asp:panel>
</td></tr></table>
</asp:panel></td></tr></table>
	<asp:hiddenfield id="MvwISDCustomerXrefRecordControl_PostbackTracker" runat="server" />
</ViewpointXRef:MvwISDCustomerXrefRecordControl>

            <%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("SaveButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("SaveAndNewButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("OKButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("EditButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("CancelButton"))%>
</td></tr><tr><td class="recordPanelButtonsAlignment"><table cellpadding="0" cellspacing="0" border="0" class="pageButtonsContainer"><tr><td><table cellpadding="0" cellspacing="0" border="0"><tr><td><ViewpointXRef:ThemeButton runat="server" id="OKButton" button-causesvalidation="False" button-commandname="Redirect" button-text="&lt;%# GetResourceValue(&quot;Btn:OK&quot;, &quot;ViewpointXRef&quot;) %>" button-tooltip="&lt;%# GetResourceValue(&quot;Btn:OK&quot;, &quot;ViewpointXRef&quot;) %>" postback="False"></ViewpointXRef:ThemeButton></td><td><ViewpointXRef:ThemeButton runat="server" id="EditButton" button-causesvalidation="False" button-commandname="Redirect" button-text="&lt;%# GetResourceValue(&quot;Btn:Edit&quot;, &quot;ViewpointXRef&quot;) %>" button-tooltip="&lt;%# GetResourceValue(&quot;Btn:Edit&quot;, &quot;ViewpointXRef&quot;) %>" postback="False" visible="False"></ViewpointXRef:ThemeButton></td></tr></table>
</td></tr></table>
</td></tr></table>
      </ContentTemplate>
</asp:UpdatePanel>

    </div>
    <div id="detailPopup" class="detailRolloverPopup" onmouseout="detailRolloverPopupClose();" onmouseover="clearTimeout(gPopupTimer);"></div>
                   <div class="QDialog" id="dialog" style="display:none;">
                          <iframe id="QuickPopupIframe" style="width:100%;height:100%;border:none"></iframe>
                   </div>                  
    <asp:ValidationSummary id="ValidationSummary1" ShowMessageBox="true" ShowSummary="false" runat="server"></asp:ValidationSummary>
</asp:Content>
                