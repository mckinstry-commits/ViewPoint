<%@ Register Tagprefix="ViewpointXRef" TagName="ThemeButton" Src="../Shared/ThemeButton.ascx" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Tagprefix="ViewpointXRef" Namespace="ViewpointXRef.UI.Controls.Show_MvwISDJobPhaseXref_Table" Assembly="ViewpointXRef" %>

<%@ Register Tagprefix="ViewpointXRef" TagName="PaginationMedium" Src="../Shared/PaginationMedium.ascx" %>

<%@ Register Tagprefix="Selectors" Namespace="ViewpointXRef" Assembly="ViewpointXRef" %>

<%@ Page Language="C#" EnableEventValidation="false" AutoEventWireup="false" Codebehind="Show-MvwISDJobPhaseXref-Table.aspx.cs" Culture="en-US" MasterPageFile="../Master Pages/HorizontalMenu.master" Inherits="ViewpointXRef.UI.Show_MvwISDJobPhaseXref_Table" %>
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

                <table cellpadding="0" cellspacing="0" border="0"><tr><td>
                        <ViewpointXRef:MvwISDJobPhaseXrefTableControl runat="server" id="MvwISDJobPhaseXrefTableControl">	<table class="dv" cellpadding="0" cellspacing="0" border="0"><tr><td class="ms-rteThemeBackColor-3-0 dh"><table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td><img src="../Images/space.gif" alt="" /></td><td><table cellpadding="0" cellspacing="0" border="0"><tr><td><asp:Literal runat="server" id="Title" Text="&lt;%#String.Concat(&quot;Job Phase Cross Reference&quot;) %>">	</asp:Literal></td></tr></table>
</td><td><img src="../Images/space.gif" alt="" /></td></tr></table>
</td></tr><tr><td><asp:panel id="CollapsibleRegion" runat="server"><table class="dBody" cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td><table cellpadding="0" cellspacing="0" border="0"><tr><td class="fila"><%# GetResourceValue("Txt:SearchFor", "ViewpointXRef") %></td><td><%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("SearchButton"))%>
<asp:TextBox runat="server" id="SearchText" columns="50" cssclass="Search_Input">	</asp:TextBox>
<asp:AutoCompleteExtender id="SearchTextAutoCompleteExtender" runat="server" TargetControlID="SearchText" ServiceMethod="GetAutoCompletionList_SearchText" MinimumPrefixLength="2" CompletionInterval="700" CompletionSetCount="10" CompletionListCssClass="autotypeahead_completionListElement" CompletionListItemCssClass="autotypeahead_listItem " CompletionListHighlightedItemCssClass="autotypeahead_highlightedListItem">
</asp:AutoCompleteExtender>
<%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("SearchButton"))%>
</td><td class="fila"><ViewpointXRef:ThemeButton runat="server" id="SearchButton" button-causesvalidation="False" button-commandname="Search" button-text="&lt;%# GetResourceValue(&quot;Btn:SearchGoButtonText&quot;, &quot;ViewpointXRef&quot;) %>" button-tooltip="&lt;%# GetResourceValue(&quot;Btn:SearchGoButtonText&quot;, &quot;ViewpointXRef&quot;) %>" postback="False"></ViewpointXRef:ThemeButton></td></tr><tr><td class="fila"><asp:Literal runat="server" id="CostTypeCodeLabel1" Text="Cost Type Code" visible="False">	</asp:Literal></td><td><%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("FilterButton"))%>
<BaseClasses:QuickSelector runat="server" id="CostTypeCodeFilter" autopostback="True" onkeypress="dropDownListTypeAhead(this,false)" redirecturl="" selectionmode="Single" visible="False">	</BaseClasses:QuickSelector><%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("FilterButton"))%>
</td><td class="filbc" rowspan="1"></td></tr></table>
</td></tr><tr><td class="ms-mwstitlearealine"><table cellpadding="0" cellspacing="0" border="0" style="width: 100%;"><tr><td><img src="../Images/paginationRowEdgeL.gif" alt="" /></td><td class="prbbc"><img src="../Images/ButtonBarEdgeL.gif" alt="" /></td><td class="prbbc"><img src="../Images/ButtonBarDividerL.gif" alt="" /></td><td class="prbbc"><asp:ImageButton runat="server" id="NewButton" causesvalidation="False" commandname="Redirect" imageurl="../Images/ButtonBarNew.gif" onmouseout="this.src='../Images/ButtonBarNew.gif'" onmouseover="this.src='../Images/ButtonBarNewOver.gif'" redirectstyle="Popup" tooltip="&lt;%# GetResourceValue(&quot;Btn:Add&quot;, &quot;ViewpointXRef&quot;) %>" visible="False">		
	</asp:ImageButton></td><td class="prbbc"><asp:ImageButton runat="server" id="PDFButton" causesvalidation="False" commandname="ReportData" imageurl="../Images/ButtonBarPDFExport.gif" onmouseout="this.src='../Images/ButtonBarPDFExport.gif'" onmouseover="this.src='../Images/ButtonBarPDFExportOver.gif'" tooltip="&lt;%# GetResourceValue(&quot;Btn:PDF&quot;, &quot;ViewpointXRef&quot;) %>">		
	</asp:ImageButton></td><td class="prbbc"><asp:ImageButton runat="server" id="WordButton" causesvalidation="False" commandname="ExportToWord" imageurl="../Images/ButtonBarWordExport.gif" onmouseout="this.src='../Images/ButtonBarWordExport.gif'" onmouseover="this.src='../Images/ButtonBarWordExportOver.gif'" tooltip="&lt;%# GetResourceValue(&quot;Btn:Word&quot;, &quot;ViewpointXRef&quot;) %>">		
	</asp:ImageButton></td><td class="prbbc"><asp:ImageButton runat="server" id="ExcelButton" causesvalidation="False" commandname="ExportDataExcel" imageurl="../Images/ButtonBarExcelExport.gif" onmouseout="this.src='../Images/ButtonBarExcelExport.gif'" onmouseover="this.src='../Images/ButtonBarExcelExportOver.gif'" tooltip="&lt;%# GetResourceValue(&quot;Btn:ExportExcel&quot;, &quot;ViewpointXRef&quot;) %>">		
	</asp:ImageButton></td><td class="prbbc"><asp:ImageButton runat="server" id="ImportButton" causesvalidation="False" commandname="ImportCSV" imageurl="../Images/ButtonBarImport.gif" onmouseout="this.src='../Images/ButtonBarImport.gif'" onmouseover="this.src='../Images/ButtonBarImportOver.gif'" tooltip="&lt;%# GetResourceValue(&quot;Btn:Import&quot;, &quot;ViewpointXRef&quot;) %>" visible="False">		
	</asp:ImageButton></td><td class="prbbc"><asp:ImageButton runat="server" id="ResetButton" causesvalidation="False" commandname="ResetFilters" imageurl="../Images/ButtonBarReset.gif" onmouseout="this.src='../Images/ButtonBarReset.gif'" onmouseover="this.src='../Images/ButtonBarResetOver.gif'" tooltip="&lt;%# GetResourceValue(&quot;Btn:Reset&quot;, &quot;ViewpointXRef&quot;) %>">		
	</asp:ImageButton></td><td class="prbbc"><img src="../Images/ButtonBarDividerR.gif" alt="" /></td><td class="prspace"><img src="../Images/ButtonBarEdgeR.gif" alt="" /></td><td class="prbbc" style="text-align:right"></td><td class="prbbc"><img src="../Images/space.gif" alt="" style="width: 10px" /></td><td class="pra"><ViewpointXRef:PaginationMedium runat="server" id="Pagination"></ViewpointXRef:PaginationMedium>
            <!--To change the position of the pagination control, please search for "prspace" on the Online Help for instruction. --></td><td><img src="../Images/paginationRowEdgeR.gif" alt="" /></td><td></td></tr></table>
</td></tr><tr><td class="tre"><table id="MvwISDJobPhaseXrefTableControlGrid" cellpadding="0" cellspacing="0" border="0" width="100%" onkeydown="captureUpDownKey(this, event)"><tr class="tch"><th class="ms-rteThemeBackColor-3-0" style="border-bottom:1px solid #CCCCCC; border-right:1px solid #CCCCCC; border-top:1px solid #CCCCCC; padding:3px;font-size: 10px;font-weight: bold;vertical-align: top;" colspan="2"><img src="../Images/space.gif" height="1" width="1" alt="" /></th><th class="ms-rteThemeBackColor-3-0" scope="col" style="border-bottom:1px solid #CCCCCC; border-right:1px solid #CCCCCC; border-top:1px solid #CCCCCC; padding:3px;font-size: 10px;font-weight: bold;vertical-align: top;"><asp:LinkButton runat="server" id="POCNameLabel" tooltip="Sort by POCName" Text="POC Name" CausesValidation="False">	</asp:LinkButton>
                        </th><th class="ms-rteThemeBackColor-3-0" scope="col" style="border-bottom:1px solid #CCCCCC; border-right:1px solid #CCCCCC; border-top:1px solid #CCCCCC; padding:3px;font-size: 10px;font-weight: bold;vertical-align: top;"><asp:LinkButton runat="server" id="JobKeyLabel" tooltip="Sort by JobKey" Text="Job Key" CausesValidation="False">	</asp:LinkButton>
                        </th><th class="ms-rteThemeBackColor-3-0" scope="col" style="border-bottom:1px solid #CCCCCC; border-right:1px solid #CCCCCC; border-top:1px solid #CCCCCC; padding:3px;font-size: 10px;font-weight: bold;vertical-align: top;"><asp:LinkButton runat="server" id="POCLabel" tooltip="Sort by POC" Text="POC" CausesValidation="False">	</asp:LinkButton>
                        </th><th class="ms-rteThemeBackColor-3-0" scope="col" style="border-bottom:1px solid #CCCCCC; border-right:1px solid #CCCCCC; border-top:1px solid #CCCCCC; padding:3px;font-size: 10px;font-weight: bold;vertical-align: top;"><asp:LinkButton runat="server" id="VPCoLabel" tooltip="Sort by VPCo" Text="VP Company" CausesValidation="False">	</asp:LinkButton>
                        </th><th class="ms-rteThemeBackColor-3-0" scope="col" style="border-bottom:1px solid #CCCCCC; border-right:1px solid #CCCCCC; border-top:1px solid #CCCCCC; padding:3px;font-size: 10px;font-weight: bold;vertical-align: top;"><asp:LinkButton runat="server" id="VPPhaseGroupLabel" tooltip="Sort by VPPhaseGroup" Text="VP Phase Group" CausesValidation="False">	</asp:LinkButton>
                        </th><th class="ms-rteThemeBackColor-3-0" scope="col" style="border-bottom:1px solid #CCCCCC; border-right:1px solid #CCCCCC; border-top:1px solid #CCCCCC; padding:3px;font-size: 10px;font-weight: bold;vertical-align: top;"><asp:LinkButton runat="server" id="CGCCoLabel" tooltip="Sort by CGCCo" Text="CGC Company" CausesValidation="False">	</asp:LinkButton>
                        </th><th class="ms-rteThemeBackColor-3-0" scope="col" style="border-bottom:1px solid #CCCCCC; border-right:1px solid #CCCCCC; border-top:1px solid #CCCCCC; padding:3px;font-size: 10px;font-weight: bold;vertical-align: top;"><asp:LinkButton runat="server" id="CGCJobLabel" tooltip="Sort by CGCJob" Text="CGC Job" CausesValidation="False">	</asp:LinkButton>
                        </th><th class="ms-rteThemeBackColor-3-0" scope="col" style="border-bottom:1px solid #CCCCCC; border-right:1px solid #CCCCCC; border-top:1px solid #CCCCCC; padding:3px;font-size: 10px;font-weight: bold;vertical-align: top;"><asp:LinkButton runat="server" id="CostTypeCodeLabel" tooltip="Sort by CostTypeCode" Text="Cost Type Code" CausesValidation="False">	</asp:LinkButton>
                        </th><th class="ms-rteThemeBackColor-3-0" scope="col" style="border-bottom:1px solid #CCCCCC; border-right:1px solid #CCCCCC; border-top:1px solid #CCCCCC; padding:3px;font-size: 10px;font-weight: bold;vertical-align: top;"><asp:LinkButton runat="server" id="CostTypeDescLabel" tooltip="Sort by CostTypeDesc" Text="Cost Type Description" CausesValidation="False">	</asp:LinkButton>
                        </th><th class="ms-rteThemeBackColor-3-0" scope="col" style="border-bottom:1px solid #CCCCCC; border-right:1px solid #CCCCCC; border-top:1px solid #CCCCCC; padding:3px;font-size: 10px;font-weight: bold;vertical-align: top;"><asp:LinkButton runat="server" id="PhaseKeyLabel" tooltip="Sort by PhaseKey" Text="Phase Key" CausesValidation="False">	</asp:LinkButton>
                        </th><th class="ms-rteThemeBackColor-3-0" scope="col" style="border-bottom:1px solid #CCCCCC; border-right:1px solid #CCCCCC; border-top:1px solid #CCCCCC; padding:3px;font-size: 10px;font-weight: bold;vertical-align: top;"><asp:LinkButton runat="server" id="VPJobLabel" tooltip="Sort by VPJob" Text="VP Job" CausesValidation="False">	</asp:LinkButton>
                        </th><th class="ms-rteThemeBackColor-3-0" scope="col" style="border-bottom:1px solid #CCCCCC; border-right:1px solid #CCCCCC; border-top:1px solid #CCCCCC; padding:3px;font-size: 10px;font-weight: bold;vertical-align: top;"><asp:LinkButton runat="server" id="VPJobDescLabel" tooltip="Sort by VPJobDesc" Text="VP Job Description" CausesValidation="False">	</asp:LinkButton>
                        </th><th class="ms-rteThemeBackColor-3-0" scope="col" style="border-bottom:1px solid #CCCCCC; border-right:1px solid #CCCCCC; border-top:1px solid #CCCCCC; padding:3px;font-size: 10px;font-weight: bold;vertical-align: top;"><asp:LinkButton runat="server" id="VPPhaseLabel" tooltip="Sort by VPPhase" Text="VP Phase" CausesValidation="False">	</asp:LinkButton>
                        </th><th class="ms-rteThemeBackColor-3-0" scope="col" style="border-bottom:1px solid #CCCCCC; border-right:1px solid #CCCCCC; border-top:1px solid #CCCCCC; padding:3px;font-size: 10px;font-weight: bold;vertical-align: top;"><asp:LinkButton runat="server" id="VPPhaseDescriptionLabel" tooltip="Sort by VPPhaseDescription" Text="VP Phase Description" CausesValidation="False">	</asp:LinkButton>
                        </th><th class="ms-rteThemeBackColor-3-0" scope="col" style="border-bottom:1px solid #CCCCCC; border-right:1px solid #CCCCCC; border-top:1px solid #CCCCCC; padding:3px;font-size: 10px;font-weight: bold;vertical-align: top;"><asp:Literal runat="server" id="ConversionNotesLabel" Text="Conversion Notes">	</asp:Literal>
                        </th></tr><asp:Repeater runat="server" id="MvwISDJobPhaseXrefTableControlRepeater">		<ITEMTEMPLATE>		<ViewpointXRef:MvwISDJobPhaseXrefTableControlRow runat="server" id="MvwISDJobPhaseXrefTableControlRow">
<tr><td class="ticnb" scope="row"><asp:ImageButton runat="server" id="EditRowButton" causesvalidation="False" commandname="Redirect" cssclass="button_link" imageurl="../Images/icon_edit.gif" onmouseout="this.src='../Images/icon_edit.gif'" onmouseover="this.src='../Images/icon_edit_over.gif'" tooltip="&lt;%# GetResourceValue(&quot;Txt:EditRecord&quot;, &quot;ViewpointXRef&quot;) %>">		
	</asp:ImageButton></td><td class="tic" scope="row"><asp:ImageButton runat="server" id="DeleteRowButton" causesvalidation="False" commandname="DeleteRecord" cssclass="button_link" imageurl="../Images/icon_delete.gif" onmouseout="this.src='../Images/icon_delete.gif'" onmouseover="this.src='../Images/icon_delete_over.gif'" tooltip="&lt;%# GetResourceValue(&quot;Txt:DeleteRecord&quot;, &quot;ViewpointXRef&quot;) %>">		
	</asp:ImageButton></td><td class="ttc"><asp:Literal runat="server" id="POCName"></asp:Literal> </td><td class="ttc"><asp:Literal runat="server" id="JobKey"></asp:Literal> </td><td class="ttc" style="text-align: right;"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="POC"></asp:Literal></span>
 </td><td class="ttc" style="text-align: right;"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="VPCo"></asp:Literal></span>
 </td><td class="ttc" style="text-align: right;"><span style="white-space:nowrap;">
<asp:Literal runat="server" id="VPPhaseGroup"></asp:Literal></span>
 </td><td class="ttc"><asp:Literal runat="server" id="CGCCo"></asp:Literal> </td><td class="ttc"><asp:Literal runat="server" id="CGCJob"></asp:Literal> </td><td class="ttc"><asp:Literal runat="server" id="CostTypeCode"></asp:Literal> </td><td class="ttc"><asp:Literal runat="server" id="CostTypeDesc"></asp:Literal> </td><td class="ttc"><asp:Literal runat="server" id="PhaseKey"></asp:Literal> </td><td class="ttc"><asp:Literal runat="server" id="VPJob"></asp:Literal> </td><td class="ttc"><asp:Literal runat="server" id="VPJobDesc"></asp:Literal> </td><td class="ttc"><asp:Literal runat="server" id="VPPhase"></asp:Literal> </td><td class="ttc"><asp:Literal runat="server" id="VPPhaseDescription"></asp:Literal> </td><td class="ttc"><asp:Literal runat="server" id="ConversionNotes"></asp:Literal> </td></tr></ViewpointXRef:MvwISDJobPhaseXrefTableControlRow>
</ITEMTEMPLATE>

</asp:Repeater>
</table>
</td></tr></table>
</asp:panel></td></tr></table>
	<asp:hiddenfield id="MvwISDJobPhaseXrefTableControl_PostbackTracker" runat="server" />
</ViewpointXRef:MvwISDJobPhaseXrefTableControl>

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
                