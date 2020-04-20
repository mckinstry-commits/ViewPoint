<%@ Page Language="C#" EnableEventValidation="false" AutoEventWireup="false" Codebehind="Show-MvwISDJobXref-Mobile.aspx.cs" Culture="en-US" MasterPageFile="../Master Pages/Mobile.master" Inherits="VPLookup.UI.Show_MvwISDJobXref_Mobile" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Tagprefix="VPLookup" TagName="PaginationMobile" Src="../Shared/PaginationMobile.ascx" %>

<%@ Register Tagprefix="VPLookup" Namespace="VPLookup.UI.Controls.Show_MvwISDJobXref_Mobile" Assembly="VPLookup" %>

<%@ Register Tagprefix="Selectors" Namespace="VPLookup" Assembly="VPLookup" %>

<%@ Register Tagprefix="BaseClasses" Namespace="BaseClasses.Web.UI.WebControls" Assembly="BaseClasses" %><asp:Content id="PageSection" ContentPlaceHolderID="PageContent" Runat="server">
    <a id="StartOfPageContent"></a>
    <div id="scrollRegion" class="scrollRegion">              
      
                <table cellpadding="0" cellspacing="0" border="0" style="width: 100%"><tr><td><%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("CancelButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("EditButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("OKButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("SaveAndNewButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("SaveButton"))%>

                        <VPLookup:MvwISDJobXrefRecordControl runat="server" id="MvwISDJobXrefRecordControl">	<table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td>
                        <table cellpadding="0" cellspacing="0" border="0" width="100%" class="mobileHeader"><tr><td class="mobileHeaderLeft">
                            <asp:ImageButton runat="server" id="CancelButton" causesvalidation="False" commandname="Redirect" imageurl="../Images/MobileButtonBack.png" text="&lt;%# GetResourceValue(&quot;Btn:Back&quot;, &quot;VPLookup&quot;) %>" tooltip="&lt;%# GetResourceValue(&quot;Btn:Back&quot;, &quot;VPLookup&quot;) %>">		
	</asp:ImageButton>
                          </td><td class="mobileHeaderTitle">
                      <asp:Literal runat="server" id="Title" Text="&lt;%#String.Concat(&quot;&lt;span class='mobileFontAdjust90'>&quot;, &quot; Job&quot;, &quot;&lt;/span>&quot;) %>">	</asp:Literal>
                    </td><td class="mobileHeaderOptions"></td><td class="mobileHeaderRight"></td></tr></table>

                      </td></tr><tr><td>
                      <asp:panel id="CollapsibleRegion" runat="server"><table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td class="mobileBody"><asp:panel id="MvwISDJobXrefRecordControlPanel" runat="server"><table class="mobileRecordPanel mobileBody" cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td class="mobileFieldValueOnTop" style="white-space: nowrap" colspan="2"><table>
<tr>
	<tdcolspan='2' class='mobileFieldValueOnLeft' style='white-space: nowrap'><b>&nbsp;<asp:Literal runat="server" id="VPJobDesc"></asp:Literal></b>
</tr>
<tr>
	<td class='mobileFieldLabelOnLeft' style='white-space: nowrap'><asp:Literal runat="server" id="VPJobLabel" Text="VP Job #">	</asp:Literal>&nbsp;</td><td style='white-space: nowrap'><asp:Literal runat="server" id="VPJob"></asp:Literal> ( <asp:Literal runat="server" id="VPCo"></asp:Literal> ) </td>
</tr>
<tr>
	<td class='mobileFieldLabelOnLeft' style='white-space: nowrap'><asp:Literal runat="server" id="CGCJobLabel" Text="CGC Job #">	</asp:Literal>&nbsp;</td><td style='white-space: nowrap'><asp:Literal runat="server" id="CGCJob"></asp:Literal> ( <asp:Literal runat="server" id="CGCCo"></asp:Literal> )</td>
</tr>
<tr>
	<td class='mobileFieldLabelOnLeft' style='white-space: nowrap'><asp:Literal runat="server" id="POCNameLabel" Text="POC">	</asp:Literal>&nbsp;</td><td style='white-space: nowrap'><asp:Literal runat="server" id="POCName"></asp:Literal> ( <asp:Literal runat="server" id="POC"></asp:Literal> ) </td>
</tr>
<tr>
	<td class='mobileFieldLabelOnLeft' style='white-space: nowrap'>Sales Person&nbsp;</td><td style='white-space: nowrap'><asp:Literal runat="server" id="SalesPersonName"></asp:Literal> ( <asp:Literal runat="server" id="SalesPerson"></asp:Literal> ) </td>
</tr>
<tr>
	<td class='mobileFieldLabelOnLeft' style='white-space: nowrap'>Customer&nbsp;</td><td style='white-space: nowrap'><asp:Literal runat="server" id="VPCustomerName"></asp:Literal> ( <asp:Literal runat="server" id="VPCustomer"></asp:Literal> )</td>
</tr>
</table></td></tr><tr><td class="mobileFieldLabelOnLeft" style="white-space: nowrap" colspan="2">Job Address</td></tr><tr><td class="mobileFieldValueOnTop" style="white-space: nowrap" colspan="2"><asp:Literal runat="server" id="MailAddress"></asp:Literal> <br />
<asp:Literal runat="server" id="MailAddress2"></asp:Literal> <br /> 
<asp:Literal runat="server" id="MailCity"></asp:Literal> ,
<asp:Literal runat="server" id="MailState"></asp:Literal> 
<asp:Literal runat="server" id="MailZip"></asp:Literal></td></tr><tr><td class="mobileFieldValueOnTop" style="white-space: nowrap"></td><td class="mobileFieldValueOnTop" style="white-space: nowrap"></td></tr><tr><td class="mobileFieldValueOnTop" style="white-space: nowrap"><asp:literal id="JobMap" runat="server"></asp:literal></td><td class="mobileFieldValueOnTop" style="white-space: nowrap"></td></tr></table></asp:panel>
</td></tr></table>
</asp:panel>
                      </td></tr></table>
	<asp:hiddenfield id="MvwISDJobXrefRecordControl_PostbackTracker" runat="server" />
</VPLookup:MvwISDJobXrefRecordControl>

            <%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("SaveButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("SaveAndNewButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("OKButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("EditButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("CancelButton"))%>
</td></tr><tr><td><asp:accordion id="MvwISDJobXrefAccordion" runat="server" requireopenedpane="false" suppressheaderpostbacks="true" selectedindex="-1">
      <panes>
          <asp:accordionpane id="MvwISDJobPhaseXrefAccordionPane" runat="server">
              <header><table border="0" cellpadding="0" cellspacing="0" style="width: 100%;">
			  <tr><td class="mobileAccordionHeader"><span class="mobileAccordionHeaderTitle">&nbsp;&nbsp;Job Phases</span></td></tr></table></header>
              <content><VPLookup:MvwISDJobPhaseXrefTableControl runat="server" id="MvwISDJobPhaseXrefTableControl">	<table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td width="100%">
                        <VPLookup:PaginationMobile runat="server" id="Pagination"></VPLookup:PaginationMobile>
                      </td></tr><tr><td>
                      <asp:panel id="CollapsibleRegion1" runat="server"><table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td class="mobileFilterArea">
                      <asp:panel id="CollapsibleRegionMobile1" style="display: none; overflow: hidden; height: 0px; width: 96%; padding-left: 2%; padding-right: 2%; margin: 0px;" cssClass="mobileBody" runat="server">
</asp:panel>
                  </td></tr><tr><td class="mobileBodyNoPadding"><table id="MvwISDJobPhaseXrefTableControlGrid" cellpadding="0" cellspacing="0" border="0" onkeydown="captureUpDownKey(this, event)" width="100%"><tr><th class="mobileTableCell" scope="col" style="display:none"><!-- Note: Cell Is Hidden --></th><th class="mobileTableCell" scope="col" style="display:none"></th></tr><asp:Repeater runat="server" id="MvwISDJobPhaseXrefTableControlRepeater">		<ITEMTEMPLATE>		<VPLookup:MvwISDJobPhaseXrefTableControlRow runat="server" id="MvwISDJobPhaseXrefTableControlRow">
<tr onclick="RedirectByViewButton(event)"><td class="mobileTableCell" colspan="2"><table>
<tr>
	<td>Phase Code &nbsp;&nbsp;</td><td><asp:Literal runat="server" id="VPPhase"></asp:Literal></td>
</tr>
<tr>
	<td>Phase Desc &nbsp;&nbsp;</td><td><asp:Literal runat="server" id="VPPhaseDescription"></asp:Literal></td>
</tr>
<tr>
	<td>Cost Type &nbsp;&nbsp;</td><td><asp:Literal runat="server" id="CostTypeDesc"></asp:Literal> ( <asp:Literal runat="server" id="CostTypeCode"></asp:Literal> )</td>
</tr>
<tr>
	<td colspan='2'><i><font size='-1'></font><asp:Literal runat="server" id="ConversionNotes"></asp:Literal></i></td>
</tr>
</table></td></tr></VPLookup:MvwISDJobPhaseXrefTableControlRow>
</ITEMTEMPLATE>

</asp:Repeater>
</table>
</td></tr></table>
</asp:panel>
                      </td></tr></table>
	<asp:hiddenfield id="MvwISDJobPhaseXrefTableControl_PostbackTracker" runat="server" />
</VPLookup:MvwISDJobPhaseXrefTableControl>
</content>
          </asp:accordionpane>
      </panes>
</asp:accordion></td></tr><tr><td><br /></td></tr></table>
      
    </div>
    <div id="detailPopup" class="detailRolloverPopup" onmouseout="detailRolloverPopupClose();" onmouseover="clearTimeout(gPopupTimer);"></div>
                   <div class="QDialog" id="dialog" style="display:none;">
                          <iframe id="QuickPopupIframe" style="width:100%;height:100%;border:none"></iframe>
                   </div>                  
    <asp:ValidationSummary id="ValidationSummary1" ShowMessageBox="true" ShowSummary="false" runat="server"></asp:ValidationSummary>
</asp:Content>
                