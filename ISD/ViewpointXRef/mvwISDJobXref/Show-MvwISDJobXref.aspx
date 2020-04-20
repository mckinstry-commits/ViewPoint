<%@ Register Tagprefix="ViewpointXRef" TagName="ThemeButton" Src="../Shared/ThemeButton.ascx" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Tagprefix="ViewpointXRef" Namespace="ViewpointXRef.UI.Controls.Show_MvwISDJobXref" Assembly="ViewpointXRef" %>

<%@ Register Tagprefix="ViewpointXRef" TagName="PaginationMedium" Src="../Shared/PaginationMedium.ascx" %>

<%@ Register Tagprefix="BaseClasses" Namespace="BaseClasses.Web.UI.WebControls" Assembly="BaseClasses" %>
<%@ Register Tagprefix="Selectors" Namespace="ViewpointXRef" Assembly="ViewpointXRef" %>

<%@ Page Language="C#" EnableEventValidation="false" AutoEventWireup="false" Codebehind="Show-MvwISDJobXref.aspx.cs" Culture="en-US" MasterPageFile="../Master Pages/HorizontalMenu.master" Inherits="ViewpointXRef.UI.Show_MvwISDJobXref" %><asp:Content id="PageSection" ContentPlaceHolderID="PageContent" Runat="server">
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

                        <ViewpointXRef:MvwISDJobXrefRecordControl runat="server" id="MvwISDJobXrefRecordControl">	<table class="dv" cellpadding="0" cellspacing="0" border="0"><tr><td class="ms-rteThemeBackColor-3-0 dh"><table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td><img src="../Images/space.gif" alt="" /></td><td><table cellpadding="0" cellspacing="0" border="0"><tr><td><asp:Literal runat="server" id="Title" Text="&lt;%#String.Concat(&quot;Job Cross Reference&quot;) %>">	</asp:Literal></td><td class="dhir"><asp:ImageButton runat="server" id="DialogEditButton" causesvalidation="False" commandname="Redirect" imageurl="../Images/iconEdit.gif" onmouseout="this.src='../Images/iconEdit.gif'" onmouseover="this.src='../Images/iconEditOver.gif'" tooltip="&lt;%# GetResourceValue(&quot;Btn:Edit&quot;, &quot;ViewpointXRef&quot;) %>" visible="False">		
	</asp:ImageButton></td></tr></table>
</td><td><img src="../Images/space.gif" alt="" /></td></tr></table>
</td></tr><tr><td><asp:panel id="CollapsibleRegion" runat="server"><table class="dBody" cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td><asp:panel id="MvwISDJobXrefRecordControlPanel" runat="server"><table cellpadding="0" cellspacing="0" border="0"><tr><td class="fls"><asp:Literal runat="server" id="VPCoLabel" Text="VP Company">	</asp:Literal></td><td class="dfv"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="VPCo"></asp:Literal></span>
</td><td class="fls"><asp:Literal runat="server" id="CGCCoLabel" Text="CGC Company">	</asp:Literal></td><td class="dfv"><asp:Literal runat="server" id="CGCCo"></asp:Literal></td></tr><tr><td class="fls"><asp:Literal runat="server" id="VPJobLabel" Text="VP Job">	</asp:Literal></td><td class="dfv"><asp:Literal runat="server" id="VPJob"></asp:Literal></td><td class="fls"><asp:Literal runat="server" id="CGCJobLabel" Text="CGC Job">	</asp:Literal></td><td class="dfv"><asp:Literal runat="server" id="CGCJob"></asp:Literal></td></tr><tr><td class="fls"><asp:Literal runat="server" id="VPJobDescLabel" Text="VP Job Description">	</asp:Literal></td><td class="dfv" colspan="3"><asp:Literal runat="server" id="VPJobDesc"></asp:Literal></td></tr><tr><td class="fls"><asp:Literal runat="server" id="POCNameLabel" Text="POC Name">	</asp:Literal></td><td class="dfv"><asp:Literal runat="server" id="POCName"></asp:Literal></td><td class="fls"><asp:Literal runat="server" id="POCLabel" Text="POC">	</asp:Literal></td><td class="dfv"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="POC"></asp:Literal></span>
</td></tr><tr><td class="fls" style="vertical-align:top;"><asp:Literal runat="server" id="MailAddressLabel" Text="Address">	</asp:Literal></td><td class="dfv" colspan="3"><asp:Literal runat="server" id="MailAddress"></asp:Literal> <br />
<asp:Literal runat="server" id="MailAddress2"></asp:Literal> <br />
<asp:Literal runat="server" id="MailCity"></asp:Literal> ,
<asp:Literal runat="server" id="MailState"></asp:Literal> 
<asp:Literal runat="server" id="MailZip"></asp:Literal></td></tr></table></asp:panel>
</td></tr></table>
</asp:panel></td></tr></table>
	<asp:hiddenfield id="MvwISDJobXrefRecordControl_PostbackTracker" runat="server" />
</ViewpointXRef:MvwISDJobXrefRecordControl>

            <%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("SaveButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("SaveAndNewButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("OKButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("EditButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("CancelButton"))%>
</td></tr><tr><td><BaseClasses:TabContainer runat="server" id="MvwISDJobXrefTabContainer" panellayout="Tabbed">
 <BaseClasses:TabPanel runat="server" id="MvwISDJobPhaseXrefTabPanel" HeaderText="Job Phase Cross Reference">	<ContentTemplate>
  <ViewpointXRef:MvwISDJobPhaseXrefTableControl runat="server" id="MvwISDJobPhaseXrefTableControl">	<table class="dv" cellpadding="0" cellspacing="0" border="0"><tr><td><asp:panel id="CollapsibleRegion1" runat="server"><table class="dBody" cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td class="ms-mwstitlearealine"><table cellpadding="0" cellspacing="0" border="0" style="width: 100%;"><tr><td><img src="../Images/paginationRowEdgeL.gif" alt="" /></td><td class="prbbc"><img src="../Images/ButtonBarEdgeL.gif" alt="" /></td><td class="prbbc"><img src="../Images/ButtonBarDividerL.gif" alt="" /></td><td class="prbbc"><asp:ImageButton runat="server" id="NewButton" causesvalidation="False" commandname="Redirect" imageurl="../Images/ButtonBarNew.gif" onmouseout="this.src='../Images/ButtonBarNew.gif'" onmouseover="this.src='../Images/ButtonBarNewOver.gif'" redirectstyle="Popup" tooltip="&lt;%# GetResourceValue(&quot;Btn:Add&quot;, &quot;ViewpointXRef&quot;) %>" visible="False">		
	</asp:ImageButton></td><td class="prbbc"><asp:ImageButton runat="server" id="PDFButton" causesvalidation="False" commandname="ReportData" imageurl="../Images/ButtonBarPDFExport.gif" onmouseout="this.src='../Images/ButtonBarPDFExport.gif'" onmouseover="this.src='../Images/ButtonBarPDFExportOver.gif'" tooltip="&lt;%# GetResourceValue(&quot;Btn:PDF&quot;, &quot;ViewpointXRef&quot;) %>">		
	</asp:ImageButton></td><td class="prbbc"><asp:ImageButton runat="server" id="WordButton" causesvalidation="False" commandname="ExportToWord" imageurl="../Images/ButtonBarWordExport.gif" onmouseout="this.src='../Images/ButtonBarWordExport.gif'" onmouseover="this.src='../Images/ButtonBarWordExportOver.gif'" tooltip="&lt;%# GetResourceValue(&quot;Btn:Word&quot;, &quot;ViewpointXRef&quot;) %>">		
	</asp:ImageButton></td><td class="prbbc"><asp:ImageButton runat="server" id="ExcelButton" causesvalidation="False" commandname="ExportDataExcel" imageurl="../Images/ButtonBarExcelExport.gif" onmouseout="this.src='../Images/ButtonBarExcelExport.gif'" onmouseover="this.src='../Images/ButtonBarExcelExportOver.gif'" tooltip="&lt;%# GetResourceValue(&quot;Btn:ExportExcel&quot;, &quot;ViewpointXRef&quot;) %>">		
	</asp:ImageButton></td><td class="prbbc"><asp:ImageButton runat="server" id="ImportButton" causesvalidation="False" commandname="ImportCSV" imageurl="../Images/ButtonBarImport.gif" onmouseout="this.src='../Images/ButtonBarImport.gif'" onmouseover="this.src='../Images/ButtonBarImportOver.gif'" tooltip="&lt;%# GetResourceValue(&quot;Btn:Import&quot;, &quot;ViewpointXRef&quot;) %>" visible="False">		
	</asp:ImageButton></td><td class="prbbc"><asp:ImageButton runat="server" id="ResetButton" causesvalidation="False" commandname="ResetFilters" imageurl="../Images/ButtonBarReset.gif" onmouseout="this.src='../Images/ButtonBarReset.gif'" onmouseover="this.src='../Images/ButtonBarResetOver.gif'" tooltip="&lt;%# GetResourceValue(&quot;Btn:Reset&quot;, &quot;ViewpointXRef&quot;) %>" visible="False">		
	</asp:ImageButton></td><td class="prbbc"><img src="../Images/ButtonBarDividerR.gif" alt="" /></td><td class="prspace"><img src="../Images/ButtonBarEdgeR.gif" alt="" /></td><td class="pra"><ViewpointXRef:PaginationMedium runat="server" id="Pagination"></ViewpointXRef:PaginationMedium>
            <!--To change the position of the pagination control, please search for "prspace" on the Online Help for instruction. --></td><td><img src="../Images/paginationRowEdgeR.gif" alt="" /></td><td></td></tr></table>
</td></tr><tr><td class="tre"><table id="MvwISDJobPhaseXrefTableControlGrid" cellpadding="0" cellspacing="0" border="0" width="100%" onkeydown="captureUpDownKey(this, event)"><tr class="tch"><th class="ms-rteThemeBackColor-3-0" scope="col" style="border-bottom:1px solid #CCCCCC; border-right:1px solid #CCCCCC; border-top:1px solid #CCCCCC; padding:3px;font-size: 10px;font-weight: bold;vertical-align: top;"><asp:LinkButton runat="server" id="VPCoLabel1" tooltip="Sort by VPCo" Text="VP Company" CausesValidation="False">	</asp:LinkButton></th><th class="ms-rteThemeBackColor-3-0" scope="col" style="border-bottom:1px solid #CCCCCC; border-right:1px solid #CCCCCC; border-top:1px solid #CCCCCC; padding:3px;font-size: 10px;font-weight: bold;vertical-align: top;"><asp:LinkButton runat="server" id="VPJobLabel1" tooltip="Sort by VPJob" Text="VP Job" CausesValidation="False">	</asp:LinkButton></th><th class="ms-rteThemeBackColor-3-0" scope="col" style="border-bottom:1px solid #CCCCCC; border-right:1px solid #CCCCCC; border-top:1px solid #CCCCCC; padding:3px;font-size: 10px;font-weight: bold;vertical-align: top;"><asp:LinkButton runat="server" id="VPJobDescLabel1" tooltip="Sort by VPJobDesc" Text="VP Job Description" CausesValidation="False">	</asp:LinkButton></th><th class="ms-rteThemeBackColor-3-0" scope="col" style="border-bottom:1px solid #CCCCCC; border-right:1px solid #CCCCCC; border-top:1px solid #CCCCCC; padding:3px;font-size: 10px;font-weight: bold;vertical-align: top;"><asp:LinkButton runat="server" id="VPPhaseGroupLabel" tooltip="Sort by VPPhaseGroup" Text="VP Phase Group" CausesValidation="False">	</asp:LinkButton></th><th class="ms-rteThemeBackColor-3-0" scope="col" style="border-bottom:1px solid #CCCCCC; border-right:1px solid #CCCCCC; border-top:1px solid #CCCCCC; padding:3px;font-size: 10px;font-weight: bold;vertical-align: top;"><asp:LinkButton runat="server" id="VPPhaseLabel" tooltip="Sort by VPPhase" Text="VP Phase" CausesValidation="False">	</asp:LinkButton>
                        </th><th class="ms-rteThemeBackColor-3-0" scope="col" style="border-bottom:1px solid #CCCCCC; border-right:1px solid #CCCCCC; border-top:1px solid #CCCCCC; padding:3px;font-size: 10px;font-weight: bold;vertical-align: top;"><asp:LinkButton runat="server" id="VPPhaseDescriptionLabel" tooltip="Sort by VPPhaseDescription" Text="VP Phase Description" CausesValidation="False">	</asp:LinkButton>
                        </th><th class="ms-rteThemeBackColor-3-0" scope="col" style="border-bottom:1px solid #CCCCCC; border-right:1px solid #CCCCCC; border-top:1px solid #CCCCCC; padding:3px;font-size: 10px;font-weight: bold;vertical-align: top;"><asp:LinkButton runat="server" id="CostTypeCodeLabel" tooltip="Sort by CostTypeCode" Text="Cost Type Code" CausesValidation="False">	</asp:LinkButton></th><th class="ms-rteThemeBackColor-3-0" scope="col" style="border-bottom:1px solid #CCCCCC; border-right:1px solid #CCCCCC; border-top:1px solid #CCCCCC; padding:3px;font-size: 10px;font-weight: bold;vertical-align: top;"><asp:LinkButton runat="server" id="CostTypeDescLabel" tooltip="Sort by CostTypeDesc" Text="Cost Type Description" CausesValidation="False">	</asp:LinkButton></th><th class="ms-rteThemeBackColor-3-0" scope="col" style="border-bottom:1px solid #CCCCCC; border-right:1px solid #CCCCCC; border-top:1px solid #CCCCCC; padding:3px;font-size: 10px;font-weight: bold;vertical-align: top;"><asp:Literal runat="server" id="ConversionNotesLabel" Text="Conversion Notes">	</asp:Literal>
                        </th></tr><asp:Repeater runat="server" id="MvwISDJobPhaseXrefTableControlRepeater">		<ITEMTEMPLATE>		<ViewpointXRef:MvwISDJobPhaseXrefTableControlRow runat="server" id="MvwISDJobPhaseXrefTableControlRow">
<tr><td class="ttc"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="VPCo1"></asp:Literal></span>
</td><td class="ttc"><asp:Literal runat="server" id="VPJob1"></asp:Literal></td><td class="ttc"><asp:Literal runat="server" id="VPJobDesc1"></asp:Literal></td><td class="ttc"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="VPPhaseGroup"></asp:Literal></span>
</td><td class="ttc"><asp:Literal runat="server" id="VPPhase"></asp:Literal> </td><td class="ttc"><asp:Literal runat="server" id="VPPhaseDescription"></asp:Literal> </td><td class="ttc" style="text-align: right;"><asp:Literal runat="server" id="CostTypeCode"></asp:Literal></td><td class="ttc"><asp:Literal runat="server" id="CostTypeDesc"></asp:Literal></td><td class="ttc"><asp:Literal runat="server" id="ConversionNotes"></asp:Literal> </td></tr></ViewpointXRef:MvwISDJobPhaseXrefTableControlRow>
</ITEMTEMPLATE>

</asp:Repeater>
</table>
</td></tr></table>
</asp:panel></td></tr></table>
	<asp:hiddenfield id="MvwISDJobPhaseXrefTableControl_PostbackTracker" runat="server" />
</ViewpointXRef:MvwISDJobPhaseXrefTableControl>

 </ContentTemplate></BaseClasses:TabPanel>
</BaseClasses:TabContainer></td></tr><tr><td class="recordPanelButtonsAlignment"><table cellpadding="0" cellspacing="0" border="0" class="pageButtonsContainer"><tr><td><table cellpadding="0" cellspacing="0" border="0"><tr><td><ViewpointXRef:ThemeButton runat="server" id="OKButton" button-causesvalidation="False" button-commandname="Redirect" button-text="&lt;%# GetResourceValue(&quot;Btn:OK&quot;, &quot;ViewpointXRef&quot;) %>" button-tooltip="&lt;%# GetResourceValue(&quot;Btn:OK&quot;, &quot;ViewpointXRef&quot;) %>" postback="False"></ViewpointXRef:ThemeButton></td><td><ViewpointXRef:ThemeButton runat="server" id="EditButton" button-causesvalidation="False" button-commandname="Redirect" button-text="&lt;%# GetResourceValue(&quot;Btn:Edit&quot;, &quot;ViewpointXRef&quot;) %>" button-tooltip="&lt;%# GetResourceValue(&quot;Btn:Edit&quot;, &quot;ViewpointXRef&quot;) %>" postback="False" visible="False"></ViewpointXRef:ThemeButton></td></tr></table>
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
                