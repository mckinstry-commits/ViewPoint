<%@ Register Tagprefix="ViewpointXRef" TagName="ThemeButton" Src="../Shared/ThemeButton.ascx" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Page Language="C#" EnableEventValidation="false" AutoEventWireup="false" Codebehind="Show-MvwISDJobPhaseXref.aspx.cs" Culture="en-US" MasterPageFile="../Master Pages/HorizontalMenu.master" Inherits="ViewpointXRef.UI.Show_MvwISDJobPhaseXref" %>
<%@ Register Tagprefix="Selectors" Namespace="ViewpointXRef" Assembly="ViewpointXRef" %>

<%@ Register Tagprefix="ViewpointXRef" Namespace="ViewpointXRef.UI.Controls.Show_MvwISDJobPhaseXref" Assembly="ViewpointXRef" %>

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

                        <ViewpointXRef:MvwISDJobPhaseXrefRecordControl runat="server" id="MvwISDJobPhaseXrefRecordControl">	<table class="dv" cellpadding="0" cellspacing="0" border="0"><tr><td class="ms-rteThemeBackColor-3-0 dh"><table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td><img src="../Images/space.gif" alt="" /></td><td><table cellpadding="0" cellspacing="0" border="0"><tr><td><asp:Literal runat="server" id="Title" Text="&lt;%#String.Concat(&quot;ISD Job Phase Cross Reference&quot;) %>">	</asp:Literal></td><td class="dhir"><asp:ImageButton runat="server" id="DialogEditButton" causesvalidation="False" commandname="Redirect" imageurl="../Images/iconEdit.gif" onmouseout="this.src='../Images/iconEdit.gif'" onmouseover="this.src='../Images/iconEditOver.gif'" tooltip="&lt;%# GetResourceValue(&quot;Btn:Edit&quot;, &quot;ViewpointXRef&quot;) %>">		
	</asp:ImageButton></td></tr></table>
</td><td><img src="../Images/space.gif" alt="" /></td></tr></table>
</td></tr><tr><td><asp:panel id="CollapsibleRegion" runat="server"><table class="dBody" cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td><asp:panel id="MvwISDJobPhaseXrefRecordControlPanel" runat="server"><table cellpadding="0" cellspacing="0" border="0"><tr><td class="fls"><asp:Literal runat="server" id="VPCoLabel" Text="VP Company">	</asp:Literal></td><td class="dfv"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="VPCo"></asp:Literal></span>
</td><td class="fls"><asp:Literal runat="server" id="CGCCoLabel" Text="CGC Company">	</asp:Literal></td><td class="dfv"><asp:Literal runat="server" id="CGCCo"></asp:Literal></td></tr><tr><td class="fls"><asp:Literal runat="server" id="VPJobLabel" Text="VP Job">	</asp:Literal></td><td class="dfv"><asp:Literal runat="server" id="VPJob"></asp:Literal></td><td class="fls"><asp:Literal runat="server" id="CGCJobLabel" Text="CGC Job">	</asp:Literal></td><td class="dfv"><asp:Literal runat="server" id="CGCJob"></asp:Literal></td></tr><tr><td class="fls"><asp:Literal runat="server" id="VPJobDescLabel" Text="VP Job Description">	</asp:Literal></td><td class="dfv" colspan="3"><asp:Literal runat="server" id="VPJobDesc"></asp:Literal></td></tr><tr><td class="fls"><asp:Literal runat="server" id="POCNameLabel" Text="POC Name">	</asp:Literal></td><td class="dfv"><asp:Literal runat="server" id="POCName"></asp:Literal> </td><td class="fls"><asp:Literal runat="server" id="POCLabel" Text="POC">	</asp:Literal></td><td class="dfv"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="POC"></asp:Literal></span>
 </td></tr><tr><td class="fls"><asp:Literal runat="server" id="VPPhaseGroupLabel" Text="VP Phase Group">	</asp:Literal></td><td class="dfv"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="VPPhaseGroup"></asp:Literal></span>
</td><td class="fls"></td><td class="dfv"></td></tr><tr><td class="fls"><asp:Literal runat="server" id="VPPhaseLabel" Text="VP Phase">	</asp:Literal></td><td class="dfv"><asp:Literal runat="server" id="VPPhase"></asp:Literal> </td><td class="fls"><asp:Literal runat="server" id="VPPhaseDescriptionLabel" Text="VP Phase Description">	</asp:Literal></td><td class="dfv"><asp:Literal runat="server" id="VPPhaseDescription"></asp:Literal> </td></tr><tr><td class="fls"><asp:Literal runat="server" id="CostTypeDescLabel" Text="Cost Type Description">	</asp:Literal></td><td class="dfv"><asp:Literal runat="server" id="CostTypeDesc"></asp:Literal></td><td class="fls"><asp:Literal runat="server" id="CostTypeCodeLabel" Text="Cost Type Code">	</asp:Literal></td><td class="dfv"><asp:Literal runat="server" id="CostTypeCode"></asp:Literal></td></tr><tr><td class="fls" style="vertical-align:top;"><asp:Literal runat="server" id="ConversionNotesLabel" Text="Conversion Notes">	</asp:Literal></td><td class="dfv" colspan="3"><asp:Literal runat="server" id="ConversionNotes"></asp:Literal></td></tr><tr><td class="fls"><asp:Literal runat="server" id="JobKeyLabel" Text="Job Key" visible="False">	</asp:Literal></td><td class="dfv"><asp:Literal runat="server" id="JobKey" visible="False"></asp:Literal> </td><td class="fls"></td><td class="dfv"></td></tr><tr><td class="fls"><asp:Literal runat="server" id="PhaseKeyLabel" Text="Phase Key" visible="False">	</asp:Literal></td><td class="dfv"><asp:Literal runat="server" id="PhaseKey" visible="False"></asp:Literal></td><td class="dfv"></td><td class="dfv"></td></tr></table></asp:panel>
</td></tr></table>
</asp:panel></td></tr></table>
	<asp:hiddenfield id="MvwISDJobPhaseXrefRecordControl_PostbackTracker" runat="server" />
</ViewpointXRef:MvwISDJobPhaseXrefRecordControl>

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
                