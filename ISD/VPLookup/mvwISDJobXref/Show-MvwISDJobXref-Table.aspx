<%@ Register Tagprefix="VPLookup" TagName="PaginationModern" Src="../Shared/PaginationModern.ascx" %>

<%@ Register Tagprefix="VPLookup" TagName="ThemeButtonWithArrow" Src="../Shared/ThemeButtonWithArrow.ascx" %>

<%@ Page Language="C#" EnableEventValidation="false" AutoEventWireup="false" Codebehind="Show-MvwISDJobXref-Table.aspx.cs" Culture="en-US" MasterPageFile="../Master Pages/HorizontalMenu.master" Inherits="VPLookup.UI.Show_MvwISDJobXref_Table" %>
<%@ Register Tagprefix="Selectors" Namespace="VPLookup" Assembly="VPLookup" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Tagprefix="VPLookup" TagName="ThemeButton" Src="../Shared/ThemeButton.ascx" %>

<%@ Register Tagprefix="BaseClasses" Namespace="BaseClasses.Web.UI.WebControls" Assembly="BaseClasses" %>
<%@ Register Tagprefix="VPLookup" Namespace="VPLookup.UI.Controls.Show_MvwISDJobXref_Table" Assembly="VPLookup" %>
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
                        <VPLookup:MvwISDJobXrefTableControl runat="server" id="MvwISDJobXrefTableControl">	<table class="dv" cellpadding="0" cellspacing="0" border="0"><tr><td class="panelTL"><img src="../Images/space.gif" class="panelTLSpace" alt="" /></td><td class="panelT"></td><td class="panelTR"><img src="../Images/space.gif" class="panelTRSpace" alt="" /></td></tr><tr><td class="panelHeaderL"></td><td class="dh">
                  <table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td class="dhel"><img src="../Images/space.gif" alt="" /></td><td class="dhb"><table cellpadding="0" cellspacing="0" border="0"><tr><td class="dht" valign="middle">
                        <asp:Literal runat="server" id="Title" Text="&lt;%#String.Concat(&quot;Job Cross Reference&quot;) %>">	</asp:Literal>
                      </td></tr></table>
</td><td class="dhb"><table cellpadding="0" cellspacing="0" border="0" style="width: 100%;"><tr><td></td><td class="prbbc"></td><td class="prbbc"></td><td><div id="ActionsDiv" runat="server" class="popupWrapper">
                <table border="0" cellpadding="0" cellspacing="0"><tr><td></td><td></td><td></td><td></td><td></td><td style="text-align: right;" class="popupTableCellValue"><input type="image" src="../Images/closeButton.gif" onmouseover="this.src='../Images/closeButtonOver.gif'" onmouseout="this.src='../Images/closeButton.gif'" alt="" onclick="ISD_HidePopupPanel();return false;" align="top" /><br /></td></tr><tr><td></td><td>
                    <asp:ImageButton runat="server" id="PDFButton" causesvalidation="False" commandname="ReportData" imageurl="../Images/ButtonBarPDFExport.gif" onmouseout="this.src='../Images/ButtonBarPDFExport.gif'" onmouseover="this.src='../Images/ButtonBarPDFExportOver.gif'" tooltip="&lt;%# GetResourceValue(&quot;Btn:PDF&quot;, &quot;VPLookup&quot;) %>">		
	</asp:ImageButton>
                  </td><td>
                    <asp:ImageButton runat="server" id="WordButton" causesvalidation="False" commandname="ExportToWord" imageurl="../Images/ButtonBarWordExport.gif" onmouseout="this.src='../Images/ButtonBarWordExport.gif'" onmouseover="this.src='../Images/ButtonBarWordExportOver.gif'" tooltip="&lt;%# GetResourceValue(&quot;Btn:Word&quot;, &quot;VPLookup&quot;) %>">		
	</asp:ImageButton>
                  </td><td>
                    <asp:ImageButton runat="server" id="ExcelButton" causesvalidation="False" commandname="ExportDataExcel" imageurl="../Images/ButtonBarExcelExport.gif" onmouseout="this.src='../Images/ButtonBarExcelExport.gif'" onmouseover="this.src='../Images/ButtonBarExcelExportOver.gif'" tooltip="&lt;%# GetResourceValue(&quot;Btn:ExportExcel&quot;, &quot;VPLookup&quot;) %>">		
	</asp:ImageButton>
                  </td><td>
                    <asp:ImageButton runat="server" id="ImportButton" causesvalidation="False" commandname="ImportCSV" imageurl="../Images/ButtonBarImport.gif" onmouseout="this.src='../Images/ButtonBarImport.gif'" onmouseover="this.src='../Images/ButtonBarImportOver.gif'" tooltip="&lt;%# GetResourceValue(&quot;Btn:Import&quot;, &quot;VPLookup&quot;) %>" visible="False">		
	</asp:ImageButton>
                  </td><td></td></tr></table>

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
                          <table cellpadding="0" cellspacing="0" border="0"><tr><td class="popupTableCellLabel"></td><td class="popupTableCellValue"></td><td class="popupTableCellValue"></td><td class="popupTableCellValue"></td><td style="text-align: right;" class="popupTableCellValue"><input type="image" src="../Images/closeButton.gif" onmouseover="this.src='../Images/closeButtonOver.gif'" onmouseout="this.src='../Images/closeButton.gif'" alt="" onclick="ISD_HidePopupPanel();return false;" align="top" /><br /></td></tr><tr><td class="popupTableCellLabel"><asp:Literal runat="server" id="GLDepartmentNumberLabel1" Text="GL Department Number">	</asp:Literal></td><td colspan="2" class="popupTableCellValue"><asp:DropDownList runat="server" id="GLDepartmentNumberFilter" cssclass="Filter_Input" onkeypress="dropDownListTypeAhead(this,false)" redirecturl="" rows="5" selectionmode="Single">	</asp:DropDownList> </td><td class="popupTableCellValue"><VPLookup:ThemeButton runat="server" id="FilterButton" button-causesvalidation="False" button-commandname="Search" button-text="&lt;%# GetResourceValue(&quot;Btn:SearchGoButtonText&quot;, &quot;VPLookup&quot;) %>" button-tooltip="&lt;%# GetResourceValue(&quot;Btn:SearchGoButtonText&quot;, &quot;VPLookup&quot;) %>" postback="False"></VPLookup:ThemeButton></td><td class="popupTableCellValue">
                                  <asp:ImageButton runat="server" id="ResetButton" causesvalidation="False" commandname="ResetFilters" imageurl="../Images/ButtonBarReset.gif" onmouseout="this.src='../Images/ButtonBarReset.gif'" onmouseover="this.src='../Images/ButtonBarResetOver.gif'" tooltip="&lt;%# GetResourceValue(&quot;Btn:Reset&quot;, &quot;VPLookup&quot;) %>">		
	</asp:ImageButton>
                                </td></tr><tr><td class="popupTableCellLabel"><asp:Literal runat="server" id="JobStatusLabel" Text="Job Status">	</asp:Literal></td><td class="popupTableCellValue"><asp:DropDownList runat="server" id="JobStatusFilter" cssclass="Filter_Input" onkeypress="dropDownListTypeAhead(this,false)" redirecturl="" selectionmode="Single">	</asp:DropDownList></td><td class="popupTableCellValue"></td><td class="popupTableCellValue"></td><td class="popupTableCellValue"></td></tr><tr><td class="popupTableCellLabel"><asp:Literal runat="server" id="POCNameLabel1" Text="POC Name">	</asp:Literal></td><td class="popupTableCellValue"><BaseClasses:QuickSelector runat="server" id="POCNameFilter" onkeypress="dropDownListTypeAhead(this,false)" redirecturl="" selectionmode="Single">	</BaseClasses:QuickSelector> </td><td class="popupTableCellValue"></td><td class="popupTableCellValue"></td><td class="popupTableCellValue"></td></tr><tr><td class="popupTableCellLabel"><asp:Literal runat="server" id="SalesPersonNameLabel1" Text="Sales Person Name">	</asp:Literal></td><td class="popupTableCellValue"><BaseClasses:QuickSelector runat="server" id="SalesPersonNameFilter" onkeypress="dropDownListTypeAhead(this,false)" redirecturl="" selectionmode="Single">	</BaseClasses:QuickSelector> </td><td class="popupTableCellValue"></td><td class="popupTableCellValue"></td><td class="popupTableCellValue"></td></tr><tr><td class="popupTableCellLabel"><asp:Literal runat="server" id="VPCustomerNameLabel1" Text="VP Customer Name">	</asp:Literal></td><td class="popupTableCellValue"><BaseClasses:QuickSelector runat="server" id="VPCustomerNameFilter" onkeypress="dropDownListTypeAhead(this,false)" redirecturl="" selectionmode="Single">	</BaseClasses:QuickSelector> </td><td class="popupTableCellValue"></td><td class="popupTableCellValue"></td><td class="popupTableCellValue"></td></tr><tr><td class="popupTableCellLabel"><asp:Literal runat="server" id="MailStateLabel1" Text="State">	</asp:Literal></td><td class="popupTableCellValue"><%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("FilterButton"))%>
<BaseClasses:QuickSelector runat="server" id="MailStateFilter" onkeypress="dropDownListTypeAhead(this,false)" redirecturl="" selectionmode="Single">	</BaseClasses:QuickSelector><%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("FilterButton"))%>
</td><td class="popupTableCellValue"></td><td class="popupTableCellValue"></td><td class="popupTableCellValue"></td></tr></table>

                          </div>
                        </td><td class="dher"><img src="../Images/space.gif" alt="" /></td></tr></table>

                </td><td class="panelHeaderR"></td></tr><tr><td class="panelL"></td><td>
                  <asp:panel id="CollapsibleRegion" runat="server"><table class="dBody" cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td class="tre"><table id="MvwISDJobXrefTableControlGrid" cellpadding="0" cellspacing="0" border="0" width="100%" onkeydown="captureUpDownKey(this, event)"><tr class="tch"><th class="thc" colspan="2" style="white-space: nowrap"><img src="../Images/space.gif" height="1" width="1" alt="" /></th><th class="thc" style="white-space: nowrap"><asp:LinkButton runat="server" id="VPCoLabel" Text="VP Company" CausesValidation="False">	</asp:LinkButton></th><th class="thc" style="white-space: nowrap"><asp:LinkButton runat="server" id="VPJobLabel" Text="VP Job" CausesValidation="False">	</asp:LinkButton></th><th class="thc" style="white-space: nowrap"><asp:LinkButton runat="server" id="CGCCoLabel" Text="CGC Company" CausesValidation="False">	</asp:LinkButton></th><th class="thc" style="white-space: nowrap"><asp:LinkButton runat="server" id="CGCJobLabel" Text="CGC Job" CausesValidation="False">	</asp:LinkButton></th><th class="thc" style="white-space:nowrap;text-align:left;"><asp:LinkButton runat="server" id="VPJobDescLabel" Text="VP Job Description" CausesValidation="False">	</asp:LinkButton></th><th class="thc" style="white-space:nowrap;text-align:left;"><asp:LinkButton runat="server" id="JobStatusLabel1" tooltip="Sort by JobStatus" Text="Job Status" CausesValidation="False">	</asp:LinkButton></th><th class="thc" style="white-space: nowrap"><asp:LinkButton runat="server" id="GLDepartmentNumberLabel" tooltip="Sort by GLDepartmentNumber" Text="GL Department Number" CausesValidation="False">	</asp:LinkButton></th><th class="thc" style="white-space: nowrap"><asp:LinkButton runat="server" id="GLDepartmentNameLabel" tooltip="Sort by GLDepartmentName" Text="GL Department Name" CausesValidation="False">	</asp:LinkButton></th><th class="thc" style="white-space: nowrap"><asp:LinkButton runat="server" id="VPCustomerLabel" Text="VP Customer" CausesValidation="False">	</asp:LinkButton></th><th class="thc" style="white-space: nowrap"><asp:LinkButton runat="server" id="VPCustomerNameLabel" Text="VP Customer Name" CausesValidation="False">	</asp:LinkButton></th><th class="thc" style="white-space: nowrap"><asp:LinkButton runat="server" id="POCLabel" Text="POC" CausesValidation="False">	</asp:LinkButton></th><th class="thc" style="white-space: nowrap"><asp:LinkButton runat="server" id="POCNameLabel" Text="POC Name" CausesValidation="False">	</asp:LinkButton></th><th class="thc" style="white-space: nowrap"><asp:LinkButton runat="server" id="SalesPersonLabel" Text="Sales Person" CausesValidation="False">	</asp:LinkButton></th><th class="thc" style="white-space: nowrap"><asp:LinkButton runat="server" id="SalesPersonNameLabel" Text="Sales Person Name" CausesValidation="False">	</asp:LinkButton></th><th class="thc" style="white-space: nowrap"><asp:LinkButton runat="server" id="MailAddressLabel" Text="Address" CausesValidation="False">	</asp:LinkButton></th><th class="thc" style="white-space: nowrap"><asp:LinkButton runat="server" id="MailAddress2Label" tooltip="Sort by MailAddress2" Text="Address2" CausesValidation="False">	</asp:LinkButton></th><th class="thc" style="white-space: nowrap"><asp:LinkButton runat="server" id="MailCityLabel" Text="City" CausesValidation="False">	</asp:LinkButton></th><th class="thc" style="white-space: nowrap"><asp:LinkButton runat="server" id="MailStateLabel" Text="State" CausesValidation="False">	</asp:LinkButton></th><th class="thc" style="white-space: nowrap"><asp:LinkButton runat="server" id="MailZipLabel" Text="Zip Code" CausesValidation="False">	</asp:LinkButton></th></tr><asp:Repeater runat="server" id="MvwISDJobXrefTableControlRepeater">		<ITEMTEMPLATE>		<VPLookup:MvwISDJobXrefTableControlRow runat="server" id="MvwISDJobXrefTableControlRow">
<tr><td class="tableCellValue" scope="row" style="white-space: nowrap"><asp:ImageButton runat="server" id="ViewRowButton" causesvalidation="False" commandname="Redirect" cssclass="button_link" imageurl="../Images/icon_view.gif" onmouseout="this.src='../Images/icon_view.gif'" onmouseover="this.src='../Images/icon_view_over.gif'" tooltip="&lt;%# GetResourceValue(&quot;Txt:ViewRecord&quot;, &quot;VPLookup&quot;) %>">		
	</asp:ImageButton></td><td class="tableCellValue" scope="row" style="white-space: nowrap"><asp:ImageButton runat="server" id="ExpandRowButton" causesvalidation="False" commandname="ExpandCollapseRow" cssclass="button_link" imageurl="../Images/icon_expandcollapserow.gif" onmouseout="this.src='../Images/icon_expandcollapserow.gif'" onmouseover="this.src='../Images/icon_expandcollapserow_over.gif'" tooltip="&lt;%# GetResourceValue(&quot;Txt:ExpandCollapseRow&quot;, &quot;VPLookup&quot;) %>">		
	</asp:ImageButton></td><td class="tableCellValue" style="white-space: nowrap"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="VPCo"></asp:Literal></span>
</td><td class="tableCellValue" style="white-space: nowrap"><asp:Literal runat="server" id="VPJob"></asp:Literal></td><td class="tableCellValue" style="white-space: nowrap"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="CGCCo"></asp:Literal></span>
</td><td class="tableCellValue" style="white-space: nowrap"><asp:Literal runat="server" id="CGCJob"></asp:Literal></td><td class="tableCellValue" style="white-space: nowrap"><asp:Literal runat="server" id="VPJobDesc"></asp:Literal></td><td class="tableCellValue" style="white-space: nowrap"><asp:Literal runat="server" id="JobStatus"></asp:Literal></td><td class="tableCellValue" style="white-space: nowrap"><asp:Literal runat="server" id="GLDepartmentNumber"></asp:Literal></td><td class="tableCellValue" style="white-space: nowrap"><asp:Literal runat="server" id="GLDepartmentName"></asp:Literal></td><td class="tableCellValue" style="white-space: nowrap"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="VPCustomer"></asp:Literal></span>
</td><td class="tableCellValue" style="white-space: nowrap"><asp:Literal runat="server" id="VPCustomerName"></asp:Literal></td><td class="tableCellValue" style="white-space: nowrap"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="POC"></asp:Literal></span>
</td><td class="tableCellValue" style="white-space:nowrap;vertical-align:top;"><asp:Literal runat="server" id="POCName" mode="PassThrough"></asp:Literal></td><td class="tableCellValue" style="white-space: nowrap"><asp:Literal runat="server" id="SalesPerson"></asp:Literal></td><td class="tableCellValue" style="white-space:nowrap;vertical-align:top;"><asp:Literal runat="server" id="SalesPersonName"></asp:Literal></td><td class="tableCellValue" style="white-space: nowrap"><asp:Literal runat="server" id="MailAddress"></asp:Literal></td><td class="tableCellValue" style="white-space: nowrap"><asp:Literal runat="server" id="MailAddress2"></asp:Literal></td><td class="tableCellValue" style="white-space: nowrap"><asp:Literal runat="server" id="MailCity"></asp:Literal></td><td class="tableCellValue" style="white-space: nowrap"><asp:Literal runat="server" id="MailState"></asp:Literal></td><td class="tableCellValue" style="white-space: nowrap"><asp:Literal runat="server" id="MailZip"></asp:Literal></td></tr><tr id="MvwISDJobXrefTableControlAltRow" runat="server"><td class="tableRowButton" scope="row">&nbsp; 
</td><td class="tableRowButton" scope="row">&nbsp;</td><td class="tableCellValue" colspan="5"><%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("CancelButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("EditButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("OKButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("SaveAndNewButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("SaveButton"))%>
<BaseClasses:TabContainer runat="server" id="MvwISDJobXrefTabContainer" panellayout="Tabbed">
 <BaseClasses:TabPanel runat="server" id="MvwISDCustomerXrefTabPanel" HeaderText="Customer">	<ContentTemplate>
  	<VPLookup:MvwISDCustomerXrefRecordControl runat="server" id="MvwISDCustomerXrefRecordControl">	<table class="dv" cellpadding="0" cellspacing="0" border="0"><tr><td></td></tr><tr><td>
                  <asp:panel id="CollapsibleRegion1" runat="server"><table class="dBody" cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td><asp:panel id="MvwISDCustomerXrefRecordControlPanel" runat="server"><table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td class="tableCellValue" style="white-space:nowrap;text-align:left;"><asp:Literal runat="server" id="CustomerNameLabel1" Text="Customer Name" visible="False">	</asp:Literal></td><td class="tableCellValue" style="white-space:nowrap;text-align:left;"><b><asp:Literal runat="server" id="CustomerName1"></asp:Literal></b></td><td class="tableCellValue" style="white-space:nowrap;text-align:center;border-width:1px 1px 1px 1px;border-style:solid;vertical-align:middle;" rowspan="5" colspan="3"><asp:Literal runat="server" id="CustomerMap">	</asp:Literal></td></tr><tr><td class="tableCellLabel" style="white-space: nowrap"><asp:Literal runat="server" id="VPCustomerLabel1" Text="VP Customer">	</asp:Literal></td><td class="tableCellValue" style="white-space: nowrap"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="VPCustomer1"></asp:Literal></span>
</td></tr><tr><td class="tableCellLabel" style="white-space: nowrap"><asp:Literal runat="server" id="CGCCustomerLabel" Text="CGC Customer">	</asp:Literal></td><td class="tableCellValue" style="white-space: nowrap"><asp:Literal runat="server" id="CGCCustomer"></asp:Literal></td></tr><tr><td class="tableCellLabel" style="white-space: nowrap"><asp:Literal runat="server" id="AsteaCustomerLabel" Text="Astea Customer">	</asp:Literal></td><td class="tableCellValue" style="white-space: nowrap"><asp:Literal runat="server" id="AsteaCustomer"></asp:Literal> </td></tr><tr><td class="tableCellLabel" style="white-space: nowrap"><asp:Literal runat="server" id="AddressLabel" Text="Address">	</asp:Literal></td><td class="tableCellValue" style="white-space:nowrap;text-align:left;"><asp:Literal runat="server" id="Address"></asp:Literal> <br />
<asp:Literal runat="server" id="Address2"></asp:Literal> <br /> 
<asp:Literal runat="server" id="City"></asp:Literal> ,
<asp:Literal runat="server" id="State"></asp:Literal> 
<asp:Literal runat="server" id="Zip"></asp:Literal></td></tr></table></asp:panel>
</td></tr></table>
</asp:panel>
                </td></tr></table>
	<asp:hiddenfield id="MvwISDCustomerXrefRecordControl_PostbackTracker" runat="server" />
</VPLookup:MvwISDCustomerXrefRecordControl>

 </ContentTemplate></BaseClasses:TabPanel> 
</BaseClasses:TabContainer><%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("SaveButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("SaveAndNewButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("OKButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("EditButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("CancelButton"))%>
</td><td class="tableCellValue"></td><td class="tableCellValue"></td><td class="tableCellValue"></td><td class="tableCellValue"></td><td class="tableCellValue"></td><td class="tableCellValue"></td><td class="tableCellValue"></td><td class="tableCellValue"></td><td class="tableCellValue"></td><td class="thc" style="background-color:White"></td><td class="thc" style="background-color:White"></td><td class="tableCellValue" style="background-color:White"></td><td class="tableCellValue"></td><td class="tableCellValue"></td></tr><tr><td class="tableRowDivider"></td><td class="tableRowDivider"></td><td class="tableRowDivider"></td><td class="tableRowDivider"></td><td class="tableRowDivider"></td><td class="tableRowDivider"></td><td class="tableRowDivider"></td><td class="tableRowDivider"></td><td class="tableRowDivider"></td><td class="tableRowDivider"></td><td class="tableRowDivider"></td><td class="tableRowDivider"></td><td class="tableRowDivider"></td><td class="tableRowDivider"></td><td class="tableRowDivider"></td><td class="tableRowDivider"></td><td class="tableRowDivider" style="background-color:White"></td><td class="tableRowDivider" style="background-color:White"></td><td class="tableRowDivider"></td><td class="tableRowDivider"></td><td class="tableRowDivider"></td></tr></VPLookup:MvwISDJobXrefTableControlRow>
</ITEMTEMPLATE>

</asp:Repeater>
</table>
</td></tr></table>
</asp:panel>
                </td><td class="panelR"></td></tr><tr><td class="panelL"></td><td class="panelPaginationC">
                    <VPLookup:PaginationModern runat="server" id="Pagination"></VPLookup:PaginationModern>
                    <!--To change the position of the pagination control, please search for "prspace" on the Online Help for instruction. -->
                  </td><td class="panelR"></td></tr><tr><td class="panelBL"><img src="../Images/space.gif" class="panelBLSpace" alt="" /></td><td class="panelB"></td><td class="panelBR"><img src="../Images/space.gif" class="panelBRSpace" alt="" /></td></tr></table>
	<asp:hiddenfield id="MvwISDJobXrefTableControl_PostbackTracker" runat="server" />
</VPLookup:MvwISDJobXrefTableControl>

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
                