<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Page Language="C#" EnableEventValidation="false" AutoEventWireup="false" Codebehind="MvwISDCustomerXref-QuickSelector.aspx.cs" Culture="en-US" MasterPageFile="../Master Pages/Popup.master" Inherits="VPLookup.UI.MvwISDCustomerXref_QuickSelector" %>
<%@ Register Tagprefix="VPLookup" Namespace="VPLookup.UI.Controls.MvwISDCustomerXref_QuickSelector" Assembly="VPLookup" %>

<%@ Register Tagprefix="VPLookup" TagName="PaginationModern" Src="../Shared/PaginationModern.ascx" %>

<%@ Register Tagprefix="VPLookup" TagName="ThemeButton" Src="../Shared/ThemeButton.ascx" %>

<%@ Register Tagprefix="Selectors" Namespace="VPLookup" Assembly="VPLookup" %>

<%@ Register Tagprefix="BaseClasses" Namespace="BaseClasses.Web.UI.WebControls" Assembly="BaseClasses" %><asp:Content id="PageSection" ContentPlaceHolderID="PageContent" Runat="server">
    <a id="StartOfPageContent"></a>
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

                <table cellpadding="0" cellspacing="0" border="0" style="width:100%;"><tr><td>
                        <VPLookup:SelectorTableControl runat="server" id="SelectorTableControl">	<table cellpadding="0" cellspacing="0" border="0" style="width:100%;"><tr><td class="QSdh"><table border="0" cellpadding="0" cellspacing="0" style="width:100%;"><tr><td class="panelSearchBox"><table><tr><td><%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("SearchButton"))%>

                <asp:TextBox runat="server" id="Search" columns="80" cssclass="Search_Input">	</asp:TextBox>
<asp:AutoCompleteExtender id="SearchAutoCompleteExtender" runat="server" TargetControlID="Search" ServiceMethod="GetAutoCompletionList_Search" MinimumPrefixLength="2" CompletionInterval="700" CompletionSetCount="10" CompletionListCssClass="autotypeahead_completionListElement" CompletionListItemCssClass="autotypeahead_listItem " CompletionListHighlightedItemCssClass="autotypeahead_highlightedListItem">
</asp:AutoCompleteExtender>

              <%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("SearchButton"))%>
</td><td>

                <asp:ImageButton runat="server" id="SearchButton" causesvalidation="False" commandname="Search" imageurl="../Images/panelSearchButton.png" tooltip="&lt;%# GetResourceValue(&quot;Btn:SearchGoButtonText&quot;, &quot;VPLookup&quot;) %>">		
	</asp:ImageButton>        
              </td></tr></table>
</td><td class="QSCloseButtonContainer"></td></tr></table>
</td></tr><tr><td><asp:panel id="CollapsibleRegion" runat="server"><table cellpadding="0" cellspacing="0" border="0" style="width: 100%;"><tr><td><div id="QSscrollRegion" class="QSscrollRegion"><table id="SelectorTableControlGrid" cellpadding="0" cellspacing="0" border="0" width="100%" onkeydown="captureUpDownKey(this, event)"><asp:Repeater runat="server" id="SelectorTableControlRepeater">		<ITEMTEMPLATE>		<VPLookup:SelectorTableControlRow runat="server" id="SelectorTableControlRow">
<tr class="QStr" runat="server" onmouseover="QStrMouseover(this);" onmouseout="QStrMouseout(this);"><td class="QSttc"><div><asp:Literal runat="server" id="QuickSelectorItem" Text="MyLiteral">	</asp:Literal></div></td></tr></VPLookup:SelectorTableControlRow>
</ITEMTEMPLATE>

</asp:Repeater>
</table>
</div></td></tr></table>
</asp:panel></td></tr><tr><td class="QSfooter" style="text-align: center;">
                    <!--To change the position of the pagination control, please search for "prspace" on the Online Help for instruction. --> 
<table border="0" cellpadding="0" cellspacing="0" style="width:100%;"><tr><td class="QSButtonContainer"><VPLookup:ThemeButton runat="server" id="ClearButton" button-causesvalidation="False" button-commandname="Redirect" button-onclientclick="ClearSelection();return false;" button-text="&lt;%# GetResourceValue(&quot;Btn:Clear&quot;, &quot;VPLookup&quot;) %>" button-tooltip="&lt;%# GetResourceValue(&quot;Btn:Clear&quot;, &quot;VPLookup&quot;) %>"></VPLookup:ThemeButton></td><td class="QSButtonContainer"><VPLookup:ThemeButton runat="server" id="CommitButton" button-causesvalidation="False" button-commandname="CommitSelection" button-onclientclick="CommitSelection();" button-text="OK" button-tooltip="OK"></VPLookup:ThemeButton><VPLookup:ThemeButton runat="server" id="AddButton" button-causesvalidation="False" button-commandname="Redirect" button-text="&lt;%# GetResourceValue(&quot;Btn:Add&quot;, &quot;VPLookup&quot;) %>" button-tooltip="&lt;%# GetResourceValue(&quot;Btn:Add&quot;, &quot;VPLookup&quot;) %>" isquickselectoraddbutton="True" parameterstoforward="Target,IndexField,Formula,DFKA"></VPLookup:ThemeButton></td><td class="QSPaginationContainer"><VPLookup:PaginationModern runat="server" id="Pagination" pagesizebutton-cssclass="button_link QSPageSizeButton" pagesizeselector-visible="False"></VPLookup:PaginationModern></td></tr></table>
</td></tr></table>
	<asp:hiddenfield id="SelectorTableControl_PostbackTracker" runat="server" />
</VPLookup:SelectorTableControl>

            </td></tr></table>
    </ContentTemplate>
</asp:UpdatePanel>

    <div id="detailPopup" class="detailRolloverPopup" onmouseout="detailRolloverPopupClose();" onmouseover="clearTimeout(gPopupTimer);"></div>
    <div class="QDialog" id="dialog" style="display:none;">
        <iframe id="QuickPopupIframe" style="width:100%;height:100%;border:none"></iframe>
    </div>            
    <BaseClasses:QuickSelector id="QSSelection" runat="server" style="display:none" />
    <asp:ValidationSummary id="ValidationSummary1" ShowMessageBox="true" ShowSummary="false" runat="server"></asp:ValidationSummary>
</asp:Content>
                