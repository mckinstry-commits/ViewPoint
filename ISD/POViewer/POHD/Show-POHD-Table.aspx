<%@ Register Tagprefix="Selectors" Namespace="POViewer" Assembly="POViewer" %>

<%@ Register Tagprefix="POViewer" Namespace="POViewer.UI.Controls.Show_POHD_Table" Assembly="POViewer" %>

<%@ Register Tagprefix="POViewer" TagName="ThemeButtonWithArrow" Src="../Shared/ThemeButtonWithArrow.ascx" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Tagprefix="POViewer" TagName="ThemeButton" Src="../Shared/ThemeButton.ascx" %>

<%@ Register Tagprefix="BaseClasses" Namespace="BaseClasses.Web.UI.WebControls" Assembly="BaseClasses" %>
<%@ Register Tagprefix="POViewer" TagName="PaginationModern" Src="../Shared/PaginationModern.ascx" %>

<%@ Page Language="C#" EnableEventValidation="false" AutoEventWireup="false" Codebehind="Show-POHD-Table.aspx.cs" Culture="en-US" MasterPageFile="../Master Pages/HorizontalMenu.master" Inherits="POViewer.UI.Show_POHD_Table" %><asp:Content id="PageSection" ContentPlaceHolderID="PageContent" Runat="server">
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
                        <POViewer:POHDTableControl runat="server" id="POHDTableControl">	<table class="dv" cellpadding="0" cellspacing="0" border="0"><tr><td class="panelTL"><img src="../Images/space.gif" class="panelTLSpace" alt="" /></td><td class="panelT"></td><td class="panelTR"><img src="../Images/space.gif" class="panelTRSpace" alt="" /></td></tr><tr><td class="panelHeaderL"></td><td class="dh">
                  <table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td class="dhel"><img src="../Images/space.gif" alt="" /></td><td class="dhb"><table cellpadding="0" cellspacing="0" border="0"><tr><td class="dht" valign="middle">
                        <asp:Literal runat="server" id="Title" Text="&lt;%#String.Concat(&quot;Pohd&quot;) %>">	</asp:Literal>
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
                          <table cellpadding="0" cellspacing="0" border="0"><tr><td class="popupTableCellLabel"></td><td class="popupTableCellValue"></td><td class="popupTableCellValue"></td><td class="popupTableCellValue"></td><td style="text-align: right;" class="popupTableCellValue"><input type="image" src="../Images/closeButton.gif" onmouseover="this.src='../Images/closeButtonOver.gif'" onmouseout="this.src='../Images/closeButton.gif'" alt="" onclick="ISD_HidePopupPanel();return false;" align="top" /><br /></td></tr><tr><td class="popupTableCellLabel"><asp:Literal runat="server" id="StatusLabel1" Text="Status">	</asp:Literal></td><td colspan="2" class="popupTableCellValue"><%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("FilterButton"))%>
<asp:TextBox runat="server" id="StatusFromFilter" columns="15" cssclass="Filter_Input">	</asp:TextBox>
                        <span class="rft"><%# GetResourceValue("Txt:To", "POViewer") %></span>
                        <asp:TextBox runat="server" id="StatusToFilter" columns="15" cssclass="Filter_Input">	</asp:TextBox>
                    <%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("FilterButton"))%>
</td><td class="popupTableCellValue"><POViewer:ThemeButton runat="server" id="FilterButton" button-causesvalidation="False" button-commandname="Search" button-text="&lt;%# GetResourceValue(&quot;Btn:SearchGoButtonText&quot;, &quot;POViewer&quot;) %>" button-tooltip="&lt;%# GetResourceValue(&quot;Btn:SearchGoButtonText&quot;, &quot;POViewer&quot;) %>" postback="False"></POViewer:ThemeButton></td><td class="popupTableCellValue">
                                  <asp:ImageButton runat="server" id="ResetButton" causesvalidation="False" commandname="ResetFilters" imageurl="../Images/ButtonBarReset.gif" onmouseout="this.src='../Images/ButtonBarReset.gif'" onmouseover="this.src='../Images/ButtonBarResetOver.gif'" tooltip="&lt;%# GetResourceValue(&quot;Btn:Reset&quot;, &quot;POViewer&quot;) %>">		
	</asp:ImageButton>
                                </td></tr></table>

                          </div>
                        </td><td class="dher"><img src="../Images/space.gif" alt="" /></td></tr></table>

                </td><td class="panelHeaderR"></td></tr><tr><td class="panelL"></td><td>
                  <asp:panel id="CollapsibleRegion" runat="server"><table class="dBody" cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td class="tre"><table id="POHDTableControlGrid" cellpadding="0" cellspacing="0" border="0" width="100%" onkeydown="captureUpDownKey(this, event)"><tr class="tch"><th class="thc" scope="col">
                           <asp:LinkButton runat="server" id="udAddressNameLabel" tooltip="Sort by udAddressName" Text="Address Name" CausesValidation="False">	</asp:LinkButton>    
                        </th><th class="thc" scope="col">
                           <asp:LinkButton runat="server" id="ShipInsLabel" tooltip="Sort by ShipIns" Text="Ship INS" CausesValidation="False">	</asp:LinkButton>    
                        </th><th class="thc" scope="col">
                           <asp:LinkButton runat="server" id="AddressLabel" tooltip="Sort by Address" Text="Address" CausesValidation="False">	</asp:LinkButton>    
                        </th><th class="thc" scope="col">
                           <asp:LinkButton runat="server" id="Address2Label" tooltip="Sort by Address2" Text="Address 2" CausesValidation="False">	</asp:LinkButton>    
                        </th><th class="thc" scope="col">
                           <asp:LinkButton runat="server" id="CityLabel" tooltip="Sort by City" Text="City" CausesValidation="False">	</asp:LinkButton>    
                        </th><th class="thc" scope="col">
                           <asp:LinkButton runat="server" id="StateLabel" tooltip="Sort by State" Text="State" CausesValidation="False">	</asp:LinkButton>    
                        </th><th class="thc" scope="col">
                           <asp:LinkButton runat="server" id="ZipLabel" tooltip="Sort by Zip" Text="ZIP" CausesValidation="False">	</asp:LinkButton>    
                        </th><th class="thc" scope="col">
                           <asp:LinkButton runat="server" id="CountryLabel" tooltip="Sort by Country" Text="Country" CausesValidation="False">	</asp:LinkButton>    
                        </th><th class="thc" scope="col">
                           <asp:LinkButton runat="server" id="AddedMthLabel" tooltip="Sort by AddedMth" Text="Added MTH" CausesValidation="False">	</asp:LinkButton>    
                        </th><th class="thc" scope="col">
                           <asp:LinkButton runat="server" id="ExpDateLabel" tooltip="Sort by ExpDate" Text="Expiration Date" CausesValidation="False">	</asp:LinkButton>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="InUseMthLabel" Text="In Use MTH">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="MthClosedLabel" Text="MTH Closed">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="OrderDateLabel" Text="Order Date">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="AddedBatchIDLabel" Text="Added Batch">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="INCoLabel" Text="IN Company">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="InUseBatchIdLabel" Text="In Use Batch">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="JCCoLabel" Text="JC Company">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="PayAddressSeqLabel" Text="Pay Address SEQ">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="POAddressSeqLabel" Text="PO Address SEQ">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="POCloseBatchIDLabel" Text="PO Close Batch">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="POCoLabel" Text="PO Company">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="StatusLabel" Text="Status">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="udCGCTableIDLabel" Text="CGC Table">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="udOrderedByLabel" Text="Ordered By">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="udPMSourceLabel" Text="PM Source">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="udPRCoLabel" Text="UD PR Company">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="udPurchaseContactLabel" Text="Purchase Contact">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="VendorLabel" Text="Vendor">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="VendorGroupLabel" Text="Vendor Group">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="ApprovedLabel" Text="Approved">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="ApprovedByLabel" Text="Approved By">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="AttentionLabel" Text="Attention">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="CompGroupLabel" Text="Company Group">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="DescriptionLabel" Text="Description">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="DocTypeLabel" Text="Document Type">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="HoldCodeLabel" Text="Hold Code">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="JobLabel" Text="Job">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="LocLabel" Text="Location">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="OrderedByLabel" Text="Ordered By">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="PayTermsLabel" Text="Pay Terms">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="POLabel" Text="PO">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="PurgeLabel" Text="Purge">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="ShipLocLabel" Text="Ship Location">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="udCGCTableLabel" Text="CGC">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="udConvLabel" Text="UD Conv">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="udMCKPONumberLabel" Text="MCKPO Number">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="udPOFOBLabel" Text="UD POFOB">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="udShipMethodLabel" Text="Ship Method">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="udShipToJobYNLabel" Text="Ship To Job YN">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="udSourceLabel" Text="UD Source">	</asp:Literal>    
                        </th><th class="thc" scope="col">
                           <asp:Literal runat="server" id="NotesLabel" Text="Notes">	</asp:Literal>    
                        </th></tr><asp:Repeater runat="server" id="POHDTableControlRepeater">		<ITEMTEMPLATE>		<POViewer:POHDTableControlRow runat="server" id="POHDTableControlRow">
<tr><td class="tableCellValue"><asp:Literal runat="server" id="udAddressName"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="ShipIns"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="Address"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="Address2"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="City"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="State"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="Zip"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="Country"></asp:Literal> </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="AddedMth"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="ExpDate"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="InUseMth"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="MthClosed"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="OrderDate"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="AddedBatchID"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="INCo"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="InUseBatchId"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="JCCo"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="PayAddressSeq"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="POAddressSeq"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="POCloseBatchID"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="POCo"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="Status"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="udCGCTableID"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="udOrderedBy"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="udPMSource"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="udPRCo"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="udPurchaseContact"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="Vendor"></asp:Literal></span>
 </td><td class="tableCellValue"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="VendorGroup"></asp:Literal></span>
 </td><td class="tableCellValue"><asp:Literal runat="server" id="Approved"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="ApprovedBy"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="Attention"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="CompGroup"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="Description"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="DocType"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="HoldCode"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="Job"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="Loc"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="OrderedBy"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="PayTerms"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="PO"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="Purge"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="ShipLoc"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="udCGCTable"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="udConv"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="udMCKPONumber"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="udPOFOB"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="udShipMethod"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="udShipToJobYN"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="udSource"></asp:Literal> </td><td class="tableCellValue"><asp:Literal runat="server" id="Notes"></asp:Literal> </td></tr><tr><td class="tableRowDivider" colspan="51"></td></tr></POViewer:POHDTableControlRow>
</ITEMTEMPLATE>

</asp:Repeater>
</table>
</td></tr></table>
</asp:panel>
                </td><td class="panelR"></td></tr><tr><td class="panelL"></td><td class="panelPaginationC">
                    <POViewer:PaginationModern runat="server" id="Pagination"></POViewer:PaginationModern>
                    <!--To change the position of the pagination control, please search for "prspace" on the Online Help for instruction. -->
                  </td><td class="panelR"></td></tr><tr><td class="panelBL"><img src="../Images/space.gif" class="panelBLSpace" alt="" /></td><td class="panelB"></td><td class="panelBR"><img src="../Images/space.gif" class="panelBRSpace" alt="" /></td></tr></table>
	<asp:hiddenfield id="POHDTableControl_PostbackTracker" runat="server" />
</POViewer:POHDTableControl>

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
                