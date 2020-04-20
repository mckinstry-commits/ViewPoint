<%@ Register Tagprefix="VPLookup" TagName="PaginationModern" Src="../Shared/PaginationModern.ascx" %>

<%@ Register Tagprefix="VPLookup" TagName="ThemeButtonWithArrow" Src="../Shared/ThemeButtonWithArrow.ascx" %>

<%@ Page Language="C#" EnableEventValidation="false" AutoEventWireup="false" Codebehind="Show-MvwISDJobPhaseXref-Table.aspx.cs" Culture="en-US" MasterPageFile="../Master Pages/HorizontalMenu.master" Inherits="VPLookup.UI.Show_MvwISDJobPhaseXref_Table" %>
<%@ Register Tagprefix="Selectors" Namespace="VPLookup" Assembly="VPLookup" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Tagprefix="VPLookup" TagName="ThemeButton" Src="../Shared/ThemeButton.ascx" %>

<%@ Register Tagprefix="VPLookup" Namespace="VPLookup.UI.Controls.Show_MvwISDJobPhaseXref_Table" Assembly="VPLookup" %>

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

                <table cellpadding="0" cellspacing="0" border="0" class="updatePanelContent"><tr><td>
                        <VPLookup:MvwISDJobPhaseXrefTableControl runat="server" id="MvwISDJobPhaseXrefTableControl">	<table class="dv" cellpadding="0" cellspacing="0" border="0"><tr><td class="panelTL"><img src="../Images/space.gif" class="panelTLSpace" alt="" /></td><td class="panelT"></td><td class="panelTR"><img src="../Images/space.gif" class="panelTRSpace" alt="" /></td></tr><tr><td class="panelHeaderL"></td><td class="dh">
                  <table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td class="dhel"><img src="../Images/space.gif" alt="" /></td><td class="dhb"><table cellpadding="0" cellspacing="0" border="0"><tr><td class="dht" valign="middle">
                        <asp:Literal runat="server" id="Title" Text="&lt;%#String.Concat(&quot;ISD Job Phase Cross Reference&quot;) %>">	</asp:Literal>
                      </td></tr></table>
</td><td class="dhb"><table cellpadding="0" cellspacing="0" border="0" style="width: 100%;"><tr><td></td><td class="prbbc"></td><td class="prbbc"></td><td><div id="ActionsDiv" runat="server" class="popupWrapper">
                <table border="0" cellpadding="0" cellspacing="0"><tr><td></td><td></td><td></td><td></td><td></td><td></td><td style="text-align: right;" class="popupTableCellValue"><input type="image" src="../Images/closeButton.gif" onmouseover="this.src='../Images/closeButtonOver.gif'" onmouseout="this.src='../Images/closeButton.gif'" alt="" onclick="ISD_HidePopupPanel();return false;" align="top" /><br /></td></tr><tr><td></td><td>
                    <asp:ImageButton runat="server" id="NewButton" causesvalidation="False" commandname="Redirect" imageurl="../Images/ButtonBarNew.gif" onmouseout="this.src='../Images/ButtonBarNew.gif'" onmouseover="this.src='../Images/ButtonBarNewOver.gif'" redirectstyle="Popup" tooltip="&lt;%# GetResourceValue(&quot;Btn:Add&quot;, &quot;VPLookup&quot;) %>">		
	</asp:ImageButton>
                  </td><td>
                    <asp:ImageButton runat="server" id="PDFButton" causesvalidation="False" commandname="ReportData" imageurl="../Images/ButtonBarPDFExport.gif" onmouseout="this.src='../Images/ButtonBarPDFExport.gif'" onmouseover="this.src='../Images/ButtonBarPDFExportOver.gif'" tooltip="&lt;%# GetResourceValue(&quot;Btn:PDF&quot;, &quot;VPLookup&quot;) %>">		
	</asp:ImageButton>
                  </td><td>
                    <asp:ImageButton runat="server" id="WordButton" causesvalidation="False" commandname="ExportToWord" imageurl="../Images/ButtonBarWordExport.gif" onmouseout="this.src='../Images/ButtonBarWordExport.gif'" onmouseover="this.src='../Images/ButtonBarWordExportOver.gif'" tooltip="&lt;%# GetResourceValue(&quot;Btn:Word&quot;, &quot;VPLookup&quot;) %>">		
	</asp:ImageButton>
                  </td><td>
                    <asp:ImageButton runat="server" id="ExcelButton" causesvalidation="False" commandname="ExportDataExcel" imageurl="../Images/ButtonBarExcelExport.gif" onmouseout="this.src='../Images/ButtonBarExcelExport.gif'" onmouseover="this.src='../Images/ButtonBarExcelExportOver.gif'" tooltip="&lt;%# GetResourceValue(&quot;Btn:ExportExcel&quot;, &quot;VPLookup&quot;) %>">		
	</asp:ImageButton>
                  </td><td>
                    <asp:ImageButton runat="server" id="ImportButton" causesvalidation="False" commandname="ImportCSV" imageurl="../Images/ButtonBarImport.gif" onmouseout="this.src='../Images/ButtonBarImport.gif'" onmouseover="this.src='../Images/ButtonBarImportOver.gif'" tooltip="&lt;%# GetResourceValue(&quot;Btn:Import&quot;, &quot;VPLookup&quot;) %>">		
	</asp:ImageButton>
                  </td><td></td></tr><tr><td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr></table>

                </div></td><td class="prbbc"></td><td class="prspace"></td><td class="prbbc" style="text-align:right"><VPLookup:ThemeButtonWithArrow runat="server" id="ActionsButton" button-causesvalidation="False" button-commandname="Custom" button-onclientclick="return ISD_ShowPopupPanel('ActionsDiv','ActionsButton',this);" button-text="&lt;%# GetResourceValue(&quot;Btn:Actions&quot;, &quot;VPLookup&quot;) %>" button-tooltip="&lt;%# GetResourceValue(&quot;Btn:Actions&quot;, &quot;VPLookup&quot;) %>"></VPLookup:ThemeButtonWithArrow></td><td class="prbbc" style="text-align:right">
            <VPLookup:ThemeButtonWithArrow runat="server" id="FiltersButton" button-causesvalidation="False" button-commandname="Custom" button-onclientclick="return ISD_ShowPopupPanel('FiltersDiv','FiltersButton',this);" button-text="&lt;%# GetResourceValue(&quot;Btn:Filters&quot;, &quot;VPLookup&quot;) %>" button-tooltip="&lt;%# GetResourceValue(&quot;Btn:Filters&quot;, &quot;VPLookup&quot;) %>"></VPLookup:ThemeButtonWithArrow>
          </td><td class="prbbc"><img src="../Images/space.gif" alt="" style="width: 10px" /></td><td class="panelSearchBox"><table><tr><td><%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("SearchButton"))%>

                <asp:TextBox runat="server" id="SearchText" columns="50" cssclass="Search_Input">	</asp:TextBox>
<asp:AutoCompleteExtender id="SearchTextAutoCompleteExtender" runat="server" TargetControlID="SearchText" ServiceMethod="GetAutoCompletionList_SearchText" MinimumPrefixLength="2" CompletionInterval="700" CompletionSetCount="10" CompletionListCssClass="autotypeahead_completionListElement" CompletionListItemCssClass="autotypeahead_listItem " CompletionListHighlightedItemCssClass="autotypeahead_highlightedListItem">
</asp:AutoCompleteExtender>

              <%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("SearchButton"))%>
</td><td>
                <asp:ImageButton runat="server" id="SearchButton" causesvalidation="False" commandname="Search" imageurl="../Images/panelSearchButton.png" tooltip="&lt;%# GetResourceValue(&quot;Btn:SearchGoButtonText&quot;, &quot;VPLookup&quot;) %>">		
	</asp:ImageButton>
              </td></tr></table>
</td><td class="prspaceEnd">&nbsp;</td><td></td></tr></table>
</td><td class="dher"><img src="../Images/space.gif" alt="" /></td><td>
                          <div id="FiltersDiv" runat="server" class="popupWrapper">
                          <table cellpadding="0" cellspacing="0" border="0"><tr><td class="popupTableCellLabel"></td><td class="popupTableCellValue"></td><td class="popupTableCellValue"></td><td class="popupTableCellValue"></td><td style="text-align: right;" class="popupTableCellValue"><input type="image" src="../Images/closeButton.gif" onmouseover="this.src='../Images/closeButtonOver.gif'" onmouseout="this.src='../Images/closeButton.gif'" alt="" onclick="ISD_HidePopupPanel();return false;" align="top" /><br /></td></tr><tr><td class="popupTableCellLabel"><asp:Literal runat="server" id="CostTypeCodeLabel1" Text="Cost Type Code">	</asp:Literal></td><td colspan="2" class="popupTableCellValue"><%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("FilterButton"))%>
<BaseClasses:QuickSelector runat="server" id="CostTypeCodeFilter" onkeypress="dropDownListTypeAhead(this,false)" redirecturl="" selectionmode="Single">	</BaseClasses:QuickSelector><%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("FilterButton"))%>
</td><td class="popupTableCellValue"><VPLookup:ThemeButton runat="server" id="FilterButton" button-causesvalidation="False" button-commandname="Search" button-text="&lt;%# GetResourceValue(&quot;Btn:SearchGoButtonText&quot;, &quot;VPLookup&quot;) %>" button-tooltip="&lt;%# GetResourceValue(&quot;Btn:SearchGoButtonText&quot;, &quot;VPLookup&quot;) %>" postback="False"></VPLookup:ThemeButton></td><td class="popupTableCellValue">
                                  <asp:ImageButton runat="server" id="ResetButton" causesvalidation="False" commandname="ResetFilters" imageurl="../Images/ButtonBarReset.gif" onmouseout="this.src='../Images/ButtonBarReset.gif'" onmouseover="this.src='../Images/ButtonBarResetOver.gif'" tooltip="&lt;%# GetResourceValue(&quot;Btn:Reset&quot;, &quot;VPLookup&quot;) %>">		
	</asp:ImageButton>
                                </td></tr><tr><td class="popupTableCellLabel"></td><td class="popupTableCellValue"></td><td class="popupTableCellValue"></td><td class="popupTableCellValue"></td><td class="popupTableCellValue"></td></tr><tr><td class="popupTableCellLabel"><asp:Label runat="server" id="SortByLabel" Text="&lt;%# GetResourceValue(&quot;Txt:SortBy&quot;, &quot;VPLookup&quot;) %>">	</asp:Label></td><td class="popupTableCellValue"><asp:DropDownList runat="server" id="OrderSort" autopostback="True" cssclass="Filter_Input" priorityno="1">	</asp:DropDownList></td><td class="popupTableCellValue"></td><td class="popupTableCellValue"></td><td class="popupTableCellValue"></td></tr></table>

                          </div>
                        </td><td class="dher"><img src="../Images/space.gif" alt="" /></td></tr></table>

                </td><td class="panelHeaderR"></td></tr><tr><td class="panelL"></td><td>
                  <asp:panel id="CollapsibleRegion" runat="server"><table class="dBody" cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td class="tre"><table id="MvwISDJobPhaseXrefTableControlGrid" cellpadding="0" cellspacing="0" border="0" width="100%" onkeydown="captureUpDownKey(this, event)"><tr class="tch"><th class="thc" colspan="3" style="display:none"><img src="../Images/space.gif" height="1" width="1" alt="" /></th><th class="thc" style="display: none"></th><th class="thc" style="display: none"></th><th class="thc" style="display: none"></th><th class="thc" style="display: none"></th><th class="thc" style="display: none"></th><th class="thc" style="display: none"></th></tr><asp:Repeater runat="server" id="MvwISDJobPhaseXrefTableControlRepeater">		<ITEMTEMPLATE>		<VPLookup:MvwISDJobPhaseXrefTableControlRow runat="server" id="MvwISDJobPhaseXrefTableControlRow">
<tr><td class="tableRowButtonsCellVertical" scope="row" style="font-size: 5px;" rowspan="8" colspan="3">
                                  <asp:ImageButton runat="server" id="EditRowButton" causesvalidation="False" commandname="Redirect" cssclass="button_link" imageurl="../Images/icon_edit.gif" onmouseout="this.src='../Images/icon_edit.gif'" onmouseover="this.src='../Images/icon_edit_over.gif'" tooltip="&lt;%# GetResourceValue(&quot;Txt:EditRecord&quot;, &quot;VPLookup&quot;) %>">		
	</asp:ImageButton>                                 
                                
                                  <asp:ImageButton runat="server" id="DeleteRowButton" causesvalidation="False" commandname="DeleteRecord" cssclass="button_link" imageurl="../Images/icon_delete.gif" onmouseout="this.src='../Images/icon_delete.gif'" onmouseover="this.src='../Images/icon_delete_over.gif'" tooltip="&lt;%# GetResourceValue(&quot;Txt:DeleteRecord&quot;, &quot;VPLookup&quot;) %>">		
	</asp:ImageButton>                                 
                                
                                  <asp:ImageButton runat="server" id="ExpandRowButton" causesvalidation="False" commandname="ExpandCollapseRow" cssclass="button_link" imageurl="../Images/icon_expandcollapserow.gif" onmouseout="this.src='../Images/icon_expandcollapserow.gif'" onmouseover="this.src='../Images/icon_expandcollapserow_over.gif'" tooltip="&lt;%# GetResourceValue(&quot;Txt:ExpandCollapseRow&quot;, &quot;VPLookup&quot;) %>">		
	</asp:ImageButton>
                                  
                                    <br /><br />
                                  </td><td class="tableCellLabel"><asp:Literal runat="server" id="POCNameLabel" Text="POC Name">	</asp:Literal> 
</td><td class="tableCellValue"><asp:Literal runat="server" id="POCName"></asp:Literal> </td><td class="tableCellLabel"><asp:Literal runat="server" id="CGCCoLabel" Text="CGC Company">	</asp:Literal> 
</td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="CGCCo"></asp:Literal></span>
 </td><td class="tableCellLabel"><asp:Literal runat="server" id="POCLabel" Text="POC">	</asp:Literal> 
</td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="POC"></asp:Literal></span>
 </td></tr><tr><td class="tableCellLabel"><asp:Literal runat="server" id="SalesPersonNameLabel" Text="Sales Person Name">	</asp:Literal> 
</td><td class="tableCellValue"><asp:Literal runat="server" id="SalesPersonName"></asp:Literal> </td><td class="tableCellLabel"><asp:Literal runat="server" id="CGCJobLabel" Text="CGC Job">	</asp:Literal> 
</td><td class="tableCellValue"><asp:Literal runat="server" id="CGCJob"></asp:Literal> </td><td class="tableCellLabel"><asp:Literal runat="server" id="SalesPersonLabel" Text="Sales Person">	</asp:Literal> 
</td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="SalesPerson"></asp:Literal></span>
 </td></tr><tr><td class="tableCellLabel"><asp:Literal runat="server" id="VPCustomerNameLabel" Text="VP Customer Name">	</asp:Literal> 
</td><td class="tableCellValue"><asp:Literal runat="server" id="VPCustomerName"></asp:Literal> </td><td class="tableCellLabel"><asp:Literal runat="server" id="CostTypeCodeLabel" Text="Cost Type Code">	</asp:Literal> 
</td><td class="tableCellValue"><asp:Literal runat="server" id="CostTypeCode"></asp:Literal> </td><td class="tableCellLabel"><asp:Literal runat="server" id="VPCoLabel" Text="VP Company">	</asp:Literal> 
</td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="VPCo"></asp:Literal></span>
 </td></tr><tr><td class="tableCellLabel"><asp:Literal runat="server" id="CostTypeDescLabel" Text="Cost Type Description">	</asp:Literal> 
</td><td class="tableCellValue"><asp:Literal runat="server" id="CostTypeDesc"></asp:Literal> </td><td class="tableCellLabel"><asp:Literal runat="server" id="CustomerKeyLabel" Text="Customer Key">	</asp:Literal> 
</td><td class="tableCellValue"><asp:Literal runat="server" id="CustomerKey"></asp:Literal> </td><td class="tableCellLabel"><asp:Literal runat="server" id="VPCustomerLabel" Text="VP Customer">	</asp:Literal> 
</td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="VPCustomer"></asp:Literal></span>
 </td></tr><tr><td class="tableCellLabel"><asp:Literal runat="server" id="VPJobLabel" Text="VP Job">	</asp:Literal> 
</td><td class="tableCellValue"><asp:Literal runat="server" id="VPJob"></asp:Literal> </td><td class="tableCellLabel"><asp:Literal runat="server" id="VPJobDescLabel" Text="VP Job Description">	</asp:Literal> 
</td><td class="tableCellValue"><asp:Literal runat="server" id="VPJobDesc"></asp:Literal> </td><td class="tableCellLabel"><asp:Literal runat="server" id="VPPhaseGroupLabel" Text="VP Phase Group">	</asp:Literal> 
</td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="VPPhaseGroup"></asp:Literal></span>
 </td></tr><tr><td class="tableCellLabel"><asp:Literal runat="server" id="VPPhaseLabel" Text="VP Phase">	</asp:Literal> 
</td><td class="tableCellValue"><asp:Literal runat="server" id="VPPhase"></asp:Literal> </td><td class="tableCellLabel"><asp:Literal runat="server" id="VPPhaseDescriptionLabel" Text="VP Phase Description">	</asp:Literal> 
</td><td class="tableCellValue"><asp:Literal runat="server" id="VPPhaseDescription"></asp:Literal> </td><td class="tableCellLabel"></td><td class="tableCellValue"></td></tr><tr><td class="tableCellLabel"><asp:Literal runat="server" id="PhaseKeyLabel" Text="Phase Key">	</asp:Literal> 
</td><td class="tableCellValue" colspan="5"><asp:Literal runat="server" id="PhaseKey"></asp:Literal> </td></tr><tr><td class="tableCellLabel"><asp:Literal runat="server" id="ConversionNotesLabel" Text="Conversion Notes">	</asp:Literal> 
</td><td class="tableCellValue" colspan="5"><asp:Literal runat="server" id="ConversionNotes"></asp:Literal> </td></tr><tr id="MvwISDJobPhaseXrefTableControlAltRow" runat="server"><td class="tableRowButton" scope="row">&nbsp;</td><td class="tableRowButton" scope="row">&nbsp;</td><td class="tableRowButton" scope="row">&nbsp;</td><td class="tableCellValue" colspan="6"><%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("CancelButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("EditButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("OKButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("SaveAndNewButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("SaveButton"))%>
<BaseClasses:TabContainer runat="server" id="MvwISDJobPhaseXrefTabContainer" panellayout="Tabbed">
 <BaseClasses:TabPanel runat="server" id="MvwISDJobXrefTabPanel" HeaderText="Job Key">	<ContentTemplate>
  <VPLookup:MvwISDJobXrefRecordControl runat="server" id="MvwISDJobXrefRecordControl">	<table class="dv" cellpadding="0" cellspacing="0" border="0"><tr><td></td><td></td><td></td></tr><tr><td></td><td>
                  <asp:panel id="CollapsibleRegion1" runat="server"><table class="dBody" cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td><asp:panel id="MvwISDJobXrefRecordControlPanel" runat="server"><table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td class="tableCellLabel"><asp:Literal runat="server" id="POCNameLabel1" Text="POC Name">	</asp:Literal></td><td class="tableCellValue"><asp:Literal runat="server" id="POCName2"></asp:Literal> </td><td class="tableCellLabel"><asp:Literal runat="server" id="MailAddressLabel" Text="Mail Address">	</asp:Literal></td><td class="tableCellValue"><asp:Literal runat="server" id="MailAddress"></asp:Literal> </td><td class="tableCellLabel"><asp:Literal runat="server" id="POCLabel1" Text="POC">	</asp:Literal></td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="POC2"></asp:Literal></span>
 </td></tr><tr><td class="tableCellLabel"><asp:Literal runat="server" id="SalesPersonNameLabel1" Text="Sales Person Name">	</asp:Literal></td><td class="tableCellValue"><asp:Literal runat="server" id="SalesPersonName2"></asp:Literal> </td><td class="tableCellLabel"><asp:Literal runat="server" id="MailAddress2Label" Text="Mail Address 2">	</asp:Literal></td><td class="tableCellValue"><asp:Literal runat="server" id="MailAddress2"></asp:Literal> </td><td class="tableCellLabel"><asp:Literal runat="server" id="SalesPersonLabel1" Text="Sales Person">	</asp:Literal></td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="SalesPerson2"></asp:Literal></span>
 </td></tr><tr><td class="tableCellLabel"><asp:Literal runat="server" id="VPCustomerNameLabel1" Text="VP Customer Name">	</asp:Literal></td><td class="tableCellValue"><asp:Literal runat="server" id="VPCustomerName2"></asp:Literal> </td><td class="tableCellLabel"><asp:Literal runat="server" id="MailCityLabel" Text="Mail City">	</asp:Literal></td><td class="tableCellValue"><asp:Literal runat="server" id="MailCity"></asp:Literal> </td><td class="tableCellLabel"><asp:Literal runat="server" id="VPCoLabel1" Text="VP Company">	</asp:Literal></td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="VPCo2"></asp:Literal></span>
 </td></tr><tr><td class="tableCellLabel"><asp:Literal runat="server" id="CGCCoLabel1" Text="CGC Company">	</asp:Literal></td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="CGCCo2"></asp:Literal></span>
 </td><td class="tableCellLabel"><asp:Literal runat="server" id="MailStateLabel" Text="Mail State">	</asp:Literal></td><td class="tableCellValue"><asp:Literal runat="server" id="MailState"></asp:Literal> </td><td class="tableCellLabel"><asp:Literal runat="server" id="VPCustomerLabel1" Text="VP Customer">	</asp:Literal></td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="VPCustomer1"></asp:Literal></span>
 </td></tr><tr><td class="tableCellLabel"><asp:Literal runat="server" id="CGCJobLabel1" Text="CGC Job">	</asp:Literal></td><td class="tableCellValue"><asp:Literal runat="server" id="CGCJob2"></asp:Literal> </td><td class="tableCellLabel"><asp:Literal runat="server" id="MailZipLabel" Text="Mail ZIP">	</asp:Literal></td><td class="tableCellValue"><asp:Literal runat="server" id="MailZip"></asp:Literal> </td><td class="tableCellLabel"><asp:Literal runat="server" id="VPJobLabel1" Text="VP Job">	</asp:Literal></td><td class="tableCellValue"><asp:Literal runat="server" id="VPJob1"></asp:Literal> </td></tr><tr><td class="tableCellLabel"><asp:Literal runat="server" id="VPJobDescLabel1" Text="VP Job Description">	</asp:Literal></td><td class="tableCellValue"><asp:Literal runat="server" id="VPJobDesc1"></asp:Literal> </td><td class="tableCellValue"></td><td class="tableCellValue"></td><td class="tableCellValue"></td><td class="tableCellValue"></td></tr><tr><td class="tableCellLabel"><asp:Literal runat="server" id="JobKeyLabel" Text="Job Key">	</asp:Literal></td><td class="tableCellValue" colspan="5"><asp:Literal runat="server" id="JobKey"></asp:Literal> </td></tr></table></asp:panel>
</td></tr></table>
</asp:panel>
                </td><td></td></tr><tr><td></td><td></td><td></td></tr></table>
	<asp:hiddenfield id="MvwISDJobXrefRecordControl_PostbackTracker" runat="server" />
</VPLookup:MvwISDJobXrefRecordControl>

 </ContentTemplate></BaseClasses:TabPanel>
</BaseClasses:TabContainer><%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("SaveButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("SaveAndNewButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("OKButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("EditButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("CancelButton"))%>
</td></tr><tr><td class="tableRowDivider" colspan="9"></td></tr></VPLookup:MvwISDJobPhaseXrefTableControlRow>
</ITEMTEMPLATE>

</asp:Repeater>
</table>
</td></tr></table>
</asp:panel>
                </td><td class="panelR"></td></tr><tr><td class="panelL"></td><td class="panelPaginationC">
                    <VPLookup:PaginationModern runat="server" id="Pagination"></VPLookup:PaginationModern>
                    <!--To change the position of the pagination control, please search for "prspace" on the Online Help for instruction. -->
                  </td><td class="panelR"></td></tr><tr><td class="panelBL"><img src="../Images/space.gif" class="panelBLSpace" alt="" /></td><td class="panelB"></td><td class="panelBR"><img src="../Images/space.gif" class="panelBRSpace" alt="" /></td></tr></table>
	<asp:hiddenfield id="MvwISDJobPhaseXrefTableControl_PostbackTracker" runat="server" />
</VPLookup:MvwISDJobPhaseXrefTableControl>

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
                