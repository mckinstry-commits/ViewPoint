<%@ Register Tagprefix="Selectors" Namespace="POViewer" Assembly="POViewer" %>

<%@ Register Tagprefix="POViewer" TagName="ThemeButtonWithArrow" Src="../Shared/ThemeButtonWithArrow.ascx" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Tagprefix="POViewer" TagName="ThemeButton" Src="../Shared/ThemeButton.ascx" %>

<%@ Page Language="C#" EnableEventValidation="false" AutoEventWireup="false" Codebehind="Show-POIT-Table.aspx.cs" Culture="en-US" MasterPageFile="../Master Pages/HorizontalMenu.master" Inherits="POViewer.UI.Show_POIT_Table" %>
<%@ Register Tagprefix="BaseClasses" Namespace="BaseClasses.Web.UI.WebControls" Assembly="BaseClasses" %>
<%@ Register Tagprefix="POViewer" TagName="PaginationModern" Src="../Shared/PaginationModern.ascx" %>

<%@ Register Tagprefix="POViewer" Namespace="POViewer.UI.Controls.Show_POIT_Table" Assembly="POViewer" %>
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

                <table cellpadding="0" cellspacing="0" border="0" class="updatePanelContent"><tr><td>
                        <POViewer:POITTableControl runat="server" id="POITTableControl">	<table class="dv" cellpadding="0" cellspacing="0" border="0"><tr><td class="panelTL"><img src="../Images/space.gif" class="panelTLSpace" alt="" /></td><td class="panelT"></td><td class="panelTR"><img src="../Images/space.gif" class="panelTRSpace" alt="" /></td></tr><tr><td class="panelHeaderL"></td><td class="dh">
                  <table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td class="dhel"><img src="../Images/space.gif" alt="" /></td><td class="dhb"><table cellpadding="0" cellspacing="0" border="0"><tr><td class="dht" valign="middle">
                        <asp:Literal runat="server" id="Title" Text="&lt;%#String.Concat(&quot;Poit&quot;) %>">	</asp:Literal>
                      </td></tr></table>
</td><td class="dhb"><table cellpadding="0" cellspacing="0" border="0" style="width: 100%;"><tr><td></td><td class="prbbc"></td><td class="prbbc"></td><td><div id="ActionsDiv" runat="server" class="popupWrapper">
                <table border="0" cellpadding="0" cellspacing="0"><tr><td></td><td></td><td></td><td></td><td style="text-align: right;" class="popupTableCellValue"><input type="image" src="../Images/closeButton.gif" onmouseover="this.src='../Images/closeButtonOver.gif'" onmouseout="this.src='../Images/closeButton.gif'" alt="" onclick="ISD_HidePopupPanel();return false;" align="top" /><br /></td></tr><tr><td></td><td>
                    <asp:ImageButton runat="server" id="PDFButton" causesvalidation="False" commandname="ReportData" imageurl="../Images/ButtonBarPDFExport.gif" onmouseout="this.src='../Images/ButtonBarPDFExport.gif'" onmouseover="this.src='../Images/ButtonBarPDFExportOver.gif'" tooltip="&lt;%# GetResourceValue(&quot;Btn:PDF&quot;, &quot;POViewer&quot;) %>">		
	</asp:ImageButton>
                  </td><td>
                    <asp:ImageButton runat="server" id="WordButton" causesvalidation="False" commandname="ExportToWord" imageurl="../Images/ButtonBarWordExport.gif" onmouseout="this.src='../Images/ButtonBarWordExport.gif'" onmouseover="this.src='../Images/ButtonBarWordExportOver.gif'" tooltip="&lt;%# GetResourceValue(&quot;Btn:Word&quot;, &quot;POViewer&quot;) %>">		
	</asp:ImageButton>
                  </td><td>
                    <asp:ImageButton runat="server" id="ExcelButton" causesvalidation="False" commandname="ExportDataExcel" imageurl="../Images/ButtonBarExcelExport.gif" onmouseout="this.src='../Images/ButtonBarExcelExport.gif'" onmouseover="this.src='../Images/ButtonBarExcelExportOver.gif'" tooltip="&lt;%# GetResourceValue(&quot;Btn:ExportExcel&quot;, &quot;POViewer&quot;) %>">		
	</asp:ImageButton>
                  </td><td></td></tr><tr><td></td><td></td><td></td><td></td><td></td></tr></table>

                </div></td><td class="prbbc"></td><td class="prspace"></td><td class="prbbc" style="text-align:right"><POViewer:ThemeButtonWithArrow runat="server" id="ActionsButton" button-causesvalidation="False" button-commandname="Custom" button-onclientclick="return ISD_ShowPopupPanel('ActionsDiv','ActionsButton',this);" button-text="&lt;%# GetResourceValue(&quot;Btn:Actions&quot;, &quot;POViewer&quot;) %>" button-tooltip="&lt;%# GetResourceValue(&quot;Btn:Actions&quot;, &quot;POViewer&quot;) %>"></POViewer:ThemeButtonWithArrow></td><td class="prbbc" style="text-align:right">
            <POViewer:ThemeButtonWithArrow runat="server" id="FiltersButton" button-causesvalidation="False" button-commandname="Custom" button-onclientclick="return ISD_ShowPopupPanel('FiltersDiv','FiltersButton',this);" button-text="&lt;%# GetResourceValue(&quot;Btn:Filters&quot;, &quot;POViewer&quot;) %>" button-tooltip="&lt;%# GetResourceValue(&quot;Btn:Filters&quot;, &quot;POViewer&quot;) %>"></POViewer:ThemeButtonWithArrow>
          </td><td class="prbbc"><img src="../Images/space.gif" alt="" style="width: 10px" /></td><td class="panelSearchBox"><table><tr><td><%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("SearchButton"))%>

                <asp:TextBox runat="server" id="SearchText" columns="50" cssclass="Search_Input">	</asp:TextBox>
<asp:AutoCompleteExtender id="SearchTextAutoCompleteExtender" runat="server" TargetControlID="SearchText" ServiceMethod="GetAutoCompletionList_SearchText" MinimumPrefixLength="2" CompletionInterval="700" CompletionSetCount="10" CompletionListCssClass="autotypeahead_completionListElement" CompletionListItemCssClass="autotypeahead_listItem " CompletionListHighlightedItemCssClass="autotypeahead_highlightedListItem">
</asp:AutoCompleteExtender>

              <%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("SearchButton"))%>
</td><td>
                <asp:ImageButton runat="server" id="SearchButton" causesvalidation="False" commandname="Search" imageurl="../Images/panelSearchButton.png" tooltip="&lt;%# GetResourceValue(&quot;Btn:SearchGoButtonText&quot;, &quot;POViewer&quot;) %>">		
	</asp:ImageButton>
              </td></tr></table>
</td><td class="prspaceEnd">&nbsp;</td><td></td></tr></table>
</td><td class="dher"><img src="../Images/space.gif" alt="" /></td><td>
                          <div id="FiltersDiv" runat="server" class="popupWrapper">
                          <table cellpadding="0" cellspacing="0" border="0"><tr><td class="popupTableCellLabel"></td><td class="popupTableCellValue"></td><td class="popupTableCellValue"></td><td class="popupTableCellValue"></td><td style="text-align: right;" class="popupTableCellValue"><input type="image" src="../Images/closeButton.gif" onmouseover="this.src='../Images/closeButtonOver.gif'" onmouseout="this.src='../Images/closeButton.gif'" alt="" onclick="ISD_HidePopupPanel();return false;" align="top" /><br /></td></tr><tr><td class="popupTableCellLabel"><asp:Literal runat="server" id="CompTypeLabel1" Text="Company Type">	</asp:Literal></td><td colspan="2" class="popupTableCellValue"><%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("FilterButton"))%>
<BaseClasses:QuickSelector runat="server" id="CompTypeFilter" onkeypress="dropDownListTypeAhead(this,false)" redirecturl="" selectionmode="Single">	</BaseClasses:QuickSelector><%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("FilterButton"))%>
</td><td class="popupTableCellValue"><POViewer:ThemeButton runat="server" id="FilterButton" button-causesvalidation="False" button-commandname="Search" button-text="&lt;%# GetResourceValue(&quot;Btn:SearchGoButtonText&quot;, &quot;POViewer&quot;) %>" button-tooltip="&lt;%# GetResourceValue(&quot;Btn:SearchGoButtonText&quot;, &quot;POViewer&quot;) %>" postback="False"></POViewer:ThemeButton></td><td class="popupTableCellValue">
                                  <asp:ImageButton runat="server" id="ResetButton" causesvalidation="False" commandname="ResetFilters" imageurl="../Images/ButtonBarReset.gif" onmouseout="this.src='../Images/ButtonBarReset.gif'" onmouseover="this.src='../Images/ButtonBarResetOver.gif'" tooltip="&lt;%# GetResourceValue(&quot;Btn:Reset&quot;, &quot;POViewer&quot;) %>">		
	</asp:ImageButton>
                                </td></tr></table>

                          </div>
                        </td><td class="dher"><img src="../Images/space.gif" alt="" /></td></tr></table>

                </td><td class="panelHeaderR"></td></tr><tr><td class="panelL"></td><td>
                  <asp:panel id="CollapsibleRegion" runat="server"><table class="dBody" cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td class="tre"><table id="POITTableControlGrid" cellpadding="0" cellspacing="0" border="0" width="100%" onkeydown="captureUpDownKey(this, event)"><tr class="tch"><th class="thc" scope="col">
                           <asp:LinkButton runat="server" id="POLabel" tooltip="Sort by PO" Text="PO" CausesValidation="False">	</asp:LinkButton>    
                        </th><th class="thc" scope="col">
                           <asp:LinkButton runat="server" id="AddedMthLabel" tooltip="Sort by AddedMth" Text="Added MTH" CausesValidation="False">	</asp:LinkButton>    
                        </th><th class="thc" scope="col">
                           <asp:LinkButton runat="server" id="InUseMthLabel" tooltip="Sort by InUseMth" Text="In Use MTH" CausesValidation="False">	</asp:LinkButton>    
                        </th><th class="thc" scope="col">
                           <asp:LinkButton runat="server" id="PostedDateLabel" tooltip="Sort by PostedDate" Text="Posted Date" CausesValidation="False">	</asp:LinkButton>    
                        </th><th class="thc" scope="col">
                           <asp:LinkButton runat="server" id="ReqDateLabel" tooltip="Sort by ReqDate" Text="Request Date" CausesValidation="False">	</asp:LinkButton>    
                        </th><th class="thc" scope="col">
                           <asp:LinkButton runat="server" id="udActOffDateLabel" tooltip="Sort by udActOffDate" Text="ACT Off Date" CausesValidation="False">	</asp:LinkButton>    
                        </th><th class="thc" scope="col">
                           <asp:LinkButton runat="server" id="udOnDateLabel" tooltip="Sort by udOnDate" Text="UD On Date" CausesValidation="False">	</asp:LinkButton>    
                        </th><th class="thc" scope="col">
                           <asp:LinkButton runat="server" id="udPlnOffDateLabel" tooltip="Sort by udPlnOffDate" Text="PLN Off Date" CausesValidation="False">	</asp:LinkButton>    
                        </th><th class="thc" scope="col">
                           <asp:LinkButton runat="server" id="AddedBatchIDLabel" tooltip="Sort by AddedBatchID" Text="Added Batch" CausesValidation="False">	</asp:LinkButton>    
                        </th><th class="thc" scope="col">
                           <asp:LinkButton runat="server" id="BOCostLabel" tooltip="Sort by BOCost" Text="BO Cost" CausesValidation="False">	</asp:LinkButton>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="BOUnitsLabel" Text="BO Units">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="CurCostLabel" Text="CUR Cost">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="CurTaxLabel" Text="CUR Tax">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="CurUnitCostLabel" Text="CUR Unit Cost">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="CurUnitsLabel" Text="CUR Units">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="EMCoLabel" Text="EM Company">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="EMCTypeLabel" Text="EMC Type">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="EMGroupLabel" Text="EM Group">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="GLCoLabel" Text="GL Company">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="GSTRateLabel" Text="GST Rate">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="INCoLabel" Text="IN Company">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="InUseBatchIdLabel" Text="In Use Batch">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="InvCostLabel" Text="Invoice Cost">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="InvMiscAmtLabel" Text="Invoice Misc Amount">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="InvTaxLabel" Text="Invoice Tax">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="InvUnitsLabel" Text="Invoice Units">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="ItemTypeLabel" Text="Item Type">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="JCCmtdTaxLabel" Text="JC CMTD Tax">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="JCCoLabel" Text="JC Company">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="JCCTypeLabel" Text="JCC Type">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="JCRemCmtdTaxLabel" Text="JC REM CMTD Tax">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="MatlGroupLabel" Text="Matl Group">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="OrigCostLabel" Text="Original Cost">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="OrigTaxLabel" Text="Original Tax">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="OrigUnitCostLabel" Text="Original Unit Cost">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="OrigUnitsLabel" Text="Original Units">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="PayCategoryLabel" Text="Pay Category">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="PayTypeLabel" Text="Pay Type">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="PhaseGroupLabel" Text="Phase Group">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="POCoLabel" Text="PO Company">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="POItemLabel" Text="PO Item">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="PostToCoLabel" Text="Post To Company">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="RecvdCostLabel" Text="Recvd Cost">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="RecvdUnitsLabel" Text="Recvd Units">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="RemCostLabel" Text="REM Cost">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="RemTaxLabel" Text="REM Tax">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="RemUnitsLabel" Text="REM Units">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="SMCoLabel" Text="SM Company">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="SMJCCostTypeLabel" Text="SMJC Cost Type">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="SMPhaseGroupLabel" Text="SM Phase Group">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="SMScopeLabel" Text="SM Scope">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="SMWorkOrderLabel" Text="SM Work Order">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="SupplierLabel" Text="Supplier">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="SupplierGroupLabel" Text="Supplier Group">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="TaxGroupLabel" Text="Tax Group">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="TaxRateLabel" Text="Tax Rate">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="TaxTypeLabel" Text="Tax Type">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="TotalCostLabel" Text="Total Cost">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="TotalTaxLabel" Text="Total Tax">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="TotalUnitsLabel" Text="Total Units">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="udCGCTableIDLabel" Text="CGC Table">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="WOItemLabel" Text="WO Item">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="ComponentLabel" Text="Component">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="CompTypeLabel" Text="Company Type">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="CostCodeLabel" Text="Cost Code">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="CurECMLabel" Text="CUR ECM">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="DescriptionLabel" Text="Description">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="EquipLabel" Text="Equipment">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="GLAcctLabel" Text="GL Account">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="JobLabel" Text="Job">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="LocLabel" Text="Location">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="MaterialLabel" Text="Material">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="OrigECMLabel" Text="Original ECM">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="PhaseLabel" Text="Phase">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="RecvYNLabel" Text="Received YN">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="RequisitionNumLabel" Text="Requisition Number">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="SMPhaseLabel" Text="SM Phase">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="TaxCodeLabel" Text="Tax Code">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="udCGCTableLabel" Text="CGC">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="udConvLabel" Text="UD Conv">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="udRentalNumLabel" Text="Rental Number">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="udSourceLabel" Text="UD Source">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="UMLabel" Text="UM">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="VendMatIdLabel" Text="Vend Mat">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="WOLabel" Text="WO">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="NotesLabel" Text="Notes">	</asp:Literal>    
                        </th></tr><asp:Repeater runat="server" id="POITTableControlRepeater">		<ITEMTEMPLATE>		<POViewer:POITTableControlRow runat="server" id="POITTableControlRow">
<tr><td class="tableCellValue"><asp:Literal runat="server" id="PO"></asp:Literal> </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="AddedMth"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="InUseMth"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="PostedDate"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="ReqDate"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="udActOffDate"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="udOnDate"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="udPlnOffDate"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="AddedBatchID"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="BOCost"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="BOUnits"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="CurCost"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="CurTax"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="CurUnitCost"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="CurUnits"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="EMCo"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="EMCType"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="EMGroup"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="GLCo"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="GSTRate"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="INCo"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="InUseBatchId"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="InvCost"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="InvMiscAmt"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="InvTax"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="InvUnits"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="ItemType"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="JCCmtdTax"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="JCCo"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="JCCType"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="JCRemCmtdTax"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="MatlGroup"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="OrigCost"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="OrigTax"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="OrigUnitCost"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="OrigUnits"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="PayCategory"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="PayType"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="PhaseGroup"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="POCo"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="POItem"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="PostToCo"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="RecvdCost"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="RecvdUnits"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="RemCost"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="RemTax"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="RemUnits"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="SMCo"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="SMJCCostType"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="SMPhaseGroup"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="SMScope"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="SMWorkOrder"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="Supplier"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="SupplierGroup"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="TaxGroup"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="TaxRate"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="TaxType"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="TotalCost"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="TotalTax"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="TotalUnits"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="udCGCTableID"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="WOItem"></asp:Literal></span>
 </td><td class="tableCellValue"><asp:Literal runat="server" id="Component"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="CompType"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="CostCode"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="CurECM"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="Description"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="Equip"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="GLAcct"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="Job"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="Loc"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="Material"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="OrigECM"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="Phase"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="RecvYN"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="RequisitionNum"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="SMPhase"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="TaxCode"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="udCGCTable"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="udConv"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="udRentalNum"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="udSource"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="UM"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="VendMatId"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="WO"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="Notes"></asp:Literal> </td></tr><tr><td class="tableRowDivider" colspan="86"></td></tr></POViewer:POITTableControlRow>
</ITEMTEMPLATE>

</asp:Repeater>
</table>
</td></tr></table>
</asp:panel>
                </td><td class="panelR"></td></tr><tr><td class="panelL"></td><td class="panelPaginationC">
                    <POViewer:PaginationModern runat="server" id="Pagination"></POViewer:PaginationModern>
                    <!--To change the position of the pagination control, please search for "prspace" on the Online Help for instruction. -->
                  </td><td class="panelR"></td></tr><tr><td class="panelBL"><img src="../Images/space.gif" class="panelBLSpace" alt="" /></td><td class="panelB"></td><td class="panelBR"><img src="../Images/space.gif" class="panelBRSpace" alt="" /></td></tr></table>
	<asp:hiddenfield id="POITTableControl_PostbackTracker" runat="server" />
</POViewer:POITTableControl>

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
                