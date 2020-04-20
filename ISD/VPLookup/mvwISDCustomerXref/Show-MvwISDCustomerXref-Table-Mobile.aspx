﻿<%@ Register Tagprefix="VPLookup" TagName="InfinitePaginationMobile" Src="../Shared/InfinitePaginationMobile.ascx" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Page Language="C#" EnableEventValidation="false" AutoEventWireup="false" Codebehind="Show-MvwISDCustomerXref-Table-Mobile.aspx.cs" Culture="en-US" MasterPageFile="../Master Pages/Mobile.master" Inherits="VPLookup.UI.Show_MvwISDCustomerXref_Table_Mobile" %>
<%@ Register Tagprefix="VPLookup" TagName="ThemeButtonMobile" Src="../Shared/ThemeButtonMobile.ascx" %>

<%@ Register Tagprefix="VPLookup" Namespace="VPLookup.UI.Controls.Show_MvwISDCustomerXref_Table_Mobile" Assembly="VPLookup" %>

<%@ Register Tagprefix="Selectors" Namespace="VPLookup" Assembly="VPLookup" %>

<%@ Register Tagprefix="BaseClasses" Namespace="BaseClasses.Web.UI.WebControls" Assembly="BaseClasses" %><asp:Content id="PageSection" ContentPlaceHolderID="PageContent" Runat="server">
    <a id="StartOfPageContent"></a>
    <div id="scrollRegion" class="scrollRegion">              
      
                <table cellpadding="0" cellspacing="0" border="0" style="width: 100%"><tr><td>
                        <VPLookup:MvwISDCustomerXrefTableControl runat="server" id="MvwISDCustomerXrefTableControl">	<table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td>
                        <table cellpadding="0" cellspacing="0" border="0" width="100%" class="mobileHeader"><tr><td class="mobileHeaderLeft">
                            <VPLookup:ThemeButtonMobile runat="server" id="MenuButton" button-causesvalidation="False" button-commandname="Redirect" button-text="&lt;%# GetResourceValue(&quot;Btn:Menu&quot;, &quot;VPLookup&quot;) %>" button-tooltip="&lt;%# GetResourceValue(&quot;Btn:Menu&quot;, &quot;VPLookup&quot;) %>" postback="False"></VPLookup:ThemeButtonMobile>
                          </td><td class="mobileHeaderTitle">
                      <asp:Literal runat="server" id="Title" Text="&lt;%#String.Concat(&quot;&lt;span class='mobileFontAdjust80'>&quot;, &quot;Customers&quot;, &quot;&lt;/span>&quot;) %>">	</asp:Literal>
                    </td><td class="mobileHeaderOptions">
                      <asp:CollapsiblePanelExtender id="PanelExtenderMobile" runat="server" TargetControlid="CollapsibleRegionMobile" ExpandControlID="IconMobile" CollapseControlID="IconMobile" ImageControlID="IconMobile" ExpandedImage="../images/MobileButtonFiltersCollapse.png" CollapsedImage="../images/MobileButtonFiltersExpand.png" Collapsed="true" SuppressPostBack="true" />
<asp:ImageButton id="IconMobile" runat="server" ToolTip="&lt;%# GetResourceValue(&quot;Btn:Filters&quot;) %&gt;" causesvalidation="False" imageurl="../images/MobileButtonFiltersCollapse.png" />
                    </td><td class="mobileHeaderRight"></td></tr></table>

                      </td></tr><tr><td width="100%">
                        <VPLookup:InfinitePaginationMobile runat="server" id="Pagination"></VPLookup:InfinitePaginationMobile>
                      </td></tr><tr><td>
                      <asp:panel id="CollapsibleRegion" runat="server"><table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td class="mobileFilterArea">
                      <asp:panel id="CollapsibleRegionMobile" style="display: none; overflow: hidden; height: 0px; width: 96%; padding-left: 2%; padding-right: 2%; margin: 0px;" cssClass="mobileBody" runat="server">
<table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td class="mobileFieldLabelOnTop"><%# GetResourceValue("Txt:SearchFor", "VPLookup") %></td></tr><tr><td class="mobileFieldValueOnBottom"><%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("SearchButton"))%>
<asp:TextBox runat="server" id="SearchText" columns="20" cssclass="mobileFieldInput">	</asp:TextBox><%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("SearchButton"))%>
</td></tr><tr><td class="mobileFieldValueOnBottom"><VPLookup:ThemeButtonMobile runat="server" id="SearchButton" button-causesvalidation="False" button-commandname="Search" button-text="&lt;%# GetResourceValue(&quot;Btn:SearchGoButtonText&quot;, &quot;VPLookup&quot;) %>" button-tooltip="&lt;%# GetResourceValue(&quot;Btn:SearchGoButtonText&quot;, &quot;VPLookup&quot;) %>" postback="False"></VPLookup:ThemeButtonMobile></td></tr><tr><td class="mobileFieldLabelOnTop">
              <asp:Label runat="server" id="SortByLabel" Text="&lt;%# GetResourceValue(&quot;Txt:SortBy&quot;, &quot;VPLookup&quot;) %>">	</asp:Label>
            </td></tr><tr><td class="mobileFieldValueOnBottom">
            <asp:DropDownList runat="server" id="OrderSort" autopostback="True" cssclass="mobileFilterInput" priorityno="1">	</asp:DropDownList>
          </td></tr></table>
</asp:panel>
                  </td></tr><tr><td class="mobileBody"><table id="MvwISDCustomerXrefTableControlGrid" cellpadding="0" cellspacing="0" border="0" onkeydown="captureUpDownKey(this, event)" width="100%"><tr><th class="mobileTableCell" colspan="1" style="display:none"><!-- Note: Cell Is Hidden --></th><th class="mobileTableCell" scope="col" style="display:none"><!-- Note: Cell Is Hidden --></th></tr><asp:Repeater runat="server" id="MvwISDCustomerXrefTableControlRepeater">		<ITEMTEMPLATE>		<VPLookup:MvwISDCustomerXrefTableControlRow runat="server" id="MvwISDCustomerXrefTableControlRow">
<tr onclick="RedirectByViewButton(event)"><td class="mobileTableCell" style="white-space: nowrap;display:none"><!-- Note: Cell Is Hidden --><asp:ImageButton runat="server" id="ViewRowButton" causesvalidation="False" commandname="Redirect" cssclass="button_link" imageurl="../Images/MobileButtonNext.ltr.png" tooltip="&lt;%# GetResourceValue(&quot;Txt:ViewRecord&quot;, &quot;VPLookup&quot;) %>">		
	</asp:ImageButton></td><td class="mobileTableCell" style="white-space: nowrap"><table>
<tr>
	<td colspan='2' style='white-space: nowrap'><b><asp:Label runat="server" id="CustomerName" cssclass="mobileTableCellTitle"></asp:Label></b></td>
</tr>
<tr>
	<td class='mobileFieldLabelOnLeft' style='white-space: nowrap'>VP Customer #&nbsp;&nbsp;</td><td style='white-space: nowrap'><asp:Literal runat="server" id="VPCustomer"></asp:Literal></td>
</tr>
<tr>
	<td class='mobileFieldLabelOnLeft' style='white-space: nowrap'>CGC Customer #&nbsp;&nbsp;</td><td style='white-space: nowrap'><asp:Literal runat="server" id="CGCCustomer"></asp:Literal></td>
</tr>
<tr>
	<td class='mobileFieldLabelOnLeft' style='white-space: nowrap'>Astea Customer #&nbsp;&nbsp;</td><td style='white-space: nowrap'><asp:Literal runat="server" id="AsteaCustomer"></asp:Literal></td>
</tr>
<tr>
	<td colspan='2' class='mobileFieldLabelOnLeft' style='white-space: nowrap'>Address&nbsp;&nbsp;</td>
</tr>

	<td colspan="2">
<asp:Literal runat="server" id="Address"></asp:Literal> <br />
<asp:Literal runat="server" id="Address2"></asp:Literal> <br />
<asp:Literal runat="server" id="City"></asp:Literal> ,
<asp:Literal runat="server" id="State"></asp:Literal> 
<asp:Literal runat="server" id="Zip"></asp:Literal>
	</td>

</table></td></tr></VPLookup:MvwISDCustomerXrefTableControlRow>
</ITEMTEMPLATE>

</asp:Repeater>
</table>
</td></tr></table>
</asp:panel>
                      </td></tr></table>
	<asp:hiddenfield id="MvwISDCustomerXrefTableControl_PostbackTracker" runat="server" />
</VPLookup:MvwISDCustomerXrefTableControl>

            </td></tr></table>
      
    </div>
    <div id="detailPopup" class="detailRolloverPopup" onmouseout="detailRolloverPopupClose();" onmouseover="clearTimeout(gPopupTimer);"></div>
                   <div class="QDialog" id="dialog" style="display:none;">
                          <iframe id="QuickPopupIframe" style="width:100%;height:100%;border:none"></iframe>
                   </div>                  
    <asp:ValidationSummary id="ValidationSummary1" ShowMessageBox="true" ShowSummary="false" runat="server"></asp:ValidationSummary>
</asp:Content>
                