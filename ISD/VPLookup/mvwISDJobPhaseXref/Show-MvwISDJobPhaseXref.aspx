<%@ Register Tagprefix="VPLookup" TagName="ThemeButton" Src="../Shared/ThemeButton.ascx" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Tagprefix="VPLookup" Namespace="VPLookup.UI.Controls.Show_MvwISDJobPhaseXref" Assembly="VPLookup" %>

<%@ Register Tagprefix="Selectors" Namespace="VPLookup" Assembly="VPLookup" %>

<%@ Page Language="C#" EnableEventValidation="false" AutoEventWireup="false" Codebehind="Show-MvwISDJobPhaseXref.aspx.cs" Culture="en-US" MasterPageFile="../Master Pages/HorizontalMenu.master" Inherits="VPLookup.UI.Show_MvwISDJobPhaseXref" %>
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

                <table cellpadding="0" cellspacing="0" border="0" class="updatePanelContent"><tr><td><%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("CancelButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("EditButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("OKButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("SaveAndNewButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("SaveButton"))%>

                        <VPLookup:MvwISDJobPhaseXrefRecordControl runat="server" id="MvwISDJobPhaseXrefRecordControl">	<table class="dv" cellpadding="0" cellspacing="0" border="0"><tr><td class="panelTL"><img src="../Images/space.gif" class="panelTLSpace" alt="" /></td><td class="panelT"></td><td class="panelTR"><img src="../Images/space.gif" class="panelTRSpace" alt="" /></td></tr><tr><td class="panelHeaderL"></td><td class="dh">
                  <table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td class="dhel"><img src="../Images/space.gif" alt="" /></td><td class="dhb"><table cellpadding="0" cellspacing="0" border="0"><tr><td class="dht" valign="middle">
                        <asp:Literal runat="server" id="Title" Text="&lt;%#String.Concat(&quot;ISD Job Phase Cross Reference&quot;) %>">	</asp:Literal>
                      </td><td class="dhir">
                  <asp:ImageButton runat="server" id="DialogEditButton" causesvalidation="False" commandname="Redirect" imageurl="../Images/iconEdit.gif" onmouseout="this.src='../Images/iconEdit.gif'" onmouseover="this.src='../Images/iconEditOver.gif'" tooltip="&lt;%# GetResourceValue(&quot;Btn:Edit&quot;, &quot;VPLookup&quot;) %>">		
	</asp:ImageButton>
                </td></tr></table>
</td><td class="dher"><img src="../Images/space.gif" alt="" /></td></tr></table>

                </td><td class="panelHeaderR"></td></tr><tr><td class="panelL"></td><td>
                  <asp:panel id="CollapsibleRegion" runat="server"><table class="dBody" cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td><asp:panel id="MvwISDJobPhaseXrefRecordControlPanel" runat="server"><table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td class="tableCellLabel"><asp:Literal runat="server" id="POCNameLabel" Text="POC Name">	</asp:Literal></td><td class="tableCellValue"><asp:Literal runat="server" id="POCName"></asp:Literal> </td><td class="tableCellLabel"><asp:Literal runat="server" id="POCLabel" Text="POC">	</asp:Literal></td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="POC"></asp:Literal></span>
 </td></tr><tr><td class="tableCellLabel"><asp:Literal runat="server" id="SalesPersonNameLabel" Text="Sales Person Name">	</asp:Literal></td><td class="tableCellValue"><asp:Literal runat="server" id="SalesPersonName"></asp:Literal> </td><td class="tableCellLabel"><asp:Literal runat="server" id="SalesPersonLabel" Text="Sales Person">	</asp:Literal></td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="SalesPerson"></asp:Literal></span>
 </td></tr><tr><td class="tableCellLabel"><asp:Literal runat="server" id="VPCustomerNameLabel" Text="VP Customer Name">	</asp:Literal></td><td class="tableCellValue"><asp:Literal runat="server" id="VPCustomerName"></asp:Literal> </td><td class="tableCellLabel"><asp:Literal runat="server" id="VPCoLabel" Text="VP Company">	</asp:Literal></td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="VPCo"></asp:Literal></span>
 </td></tr><tr><td class="tableCellLabel"><asp:Literal runat="server" id="CGCCoLabel" Text="CGC Company">	</asp:Literal></td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="CGCCo"></asp:Literal></span>
 </td><td class="tableCellLabel"><asp:Literal runat="server" id="VPCustomerLabel" Text="VP Customer">	</asp:Literal></td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="VPCustomer"></asp:Literal></span>
 </td></tr><tr><td class="tableCellLabel"><asp:Literal runat="server" id="CGCJobLabel" Text="CGC Job">	</asp:Literal></td><td class="tableCellValue"><asp:Literal runat="server" id="CGCJob"></asp:Literal> </td><td class="tableCellLabel"><asp:Literal runat="server" id="VPPhaseGroupLabel" Text="VP Phase Group">	</asp:Literal></td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="VPPhaseGroup"></asp:Literal></span>
 </td></tr><tr><td class="tableCellLabel"><asp:Literal runat="server" id="CostTypeCodeLabel" Text="Cost Type Code">	</asp:Literal></td><td class="tableCellValue"><asp:Literal runat="server" id="CostTypeCode"></asp:Literal> </td><td class="tableCellLabel"><asp:Literal runat="server" id="CostTypeDescLabel" Text="Cost Type Description">	</asp:Literal></td><td class="tableCellValue"><asp:Literal runat="server" id="CostTypeDesc"></asp:Literal> </td></tr><tr><td class="tableCellLabel"><asp:Literal runat="server" id="CustomerKeyLabel" Text="Customer Key">	</asp:Literal></td><td class="tableCellValue"><asp:Literal runat="server" id="CustomerKey"></asp:Literal> </td><td class="tableCellLabel"><asp:Literal runat="server" id="VPJobLabel" Text="VP Job">	</asp:Literal></td><td class="tableCellValue"><asp:Literal runat="server" id="VPJob"></asp:Literal> </td></tr><tr><td class="tableCellLabel"><asp:Literal runat="server" id="VPJobDescLabel" Text="VP Job Description">	</asp:Literal></td><td class="tableCellValue"><asp:Literal runat="server" id="VPJobDesc"></asp:Literal> </td><td class="tableCellLabel"><asp:Literal runat="server" id="VPPhaseLabel" Text="VP Phase">	</asp:Literal></td><td class="tableCellValue"><asp:Literal runat="server" id="VPPhase"></asp:Literal> </td></tr><tr><td class="tableCellLabel"><asp:Literal runat="server" id="VPPhaseDescriptionLabel" Text="VP Phase Description">	</asp:Literal></td><td class="tableCellValue"><asp:Literal runat="server" id="VPPhaseDescription"></asp:Literal> </td><td class="tableCellValue"></td><td class="tableCellValue"></td></tr><tr><td class="tableCellLabel"><asp:Literal runat="server" id="JobKeyLabel" Text="Job Key">	</asp:Literal></td><td class="tableCellValue" colspan="3"><asp:Literal runat="server" id="JobKey"></asp:Literal> </td></tr><tr><td class="tableCellLabel"><asp:Literal runat="server" id="PhaseKeyLabel" Text="Phase Key">	</asp:Literal></td><td class="tableCellValue" colspan="3"><asp:Literal runat="server" id="PhaseKey"></asp:Literal> </td></tr><tr><td class="tableCellLabel"><asp:Literal runat="server" id="ConversionNotesLabel" Text="Conversion Notes">	</asp:Literal></td><td class="tableCellValue" colspan="3"><asp:Literal runat="server" id="ConversionNotes"></asp:Literal> </td></tr></table></asp:panel>
</td></tr></table>
</asp:panel>
                </td><td class="panelR"></td></tr><tr><td class="panelBL"><img src="../Images/space.gif" class="panelBLSpace" alt="" /></td><td class="panelB"></td><td class="panelBR"><img src="../Images/space.gif" class="panelBRSpace" alt="" /></td></tr></table>
	<asp:hiddenfield id="MvwISDJobPhaseXrefRecordControl_PostbackTracker" runat="server" />
</VPLookup:MvwISDJobPhaseXrefRecordControl>

            <%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("SaveButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("SaveAndNewButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("OKButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("EditButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("CancelButton"))%>
</td></tr><tr><td class="recordPanelButtonsAlignment"><table cellpadding="0" cellspacing="0" border="0" class="pageButtonsContainer"><tr><td><table cellpadding="0" cellspacing="0" border="0"><tr><td><VPLookup:ThemeButton runat="server" id="OKButton" button-causesvalidation="False" button-commandname="Redirect" button-text="&lt;%# GetResourceValue(&quot;Btn:OK&quot;, &quot;VPLookup&quot;) %>" button-tooltip="&lt;%# GetResourceValue(&quot;Btn:OK&quot;, &quot;VPLookup&quot;) %>" postback="False"></VPLookup:ThemeButton></td><td><VPLookup:ThemeButton runat="server" id="EditButton" button-causesvalidation="False" button-commandname="Redirect" button-text="&lt;%# GetResourceValue(&quot;Btn:Edit&quot;, &quot;VPLookup&quot;) %>" button-tooltip="&lt;%# GetResourceValue(&quot;Btn:Edit&quot;, &quot;VPLookup&quot;) %>" postback="False"></VPLookup:ThemeButton></td></tr></table>
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
                