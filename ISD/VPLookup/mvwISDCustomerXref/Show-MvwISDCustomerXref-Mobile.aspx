<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Tagprefix="VPLookup" Namespace="VPLookup.UI.Controls.Show_MvwISDCustomerXref_Mobile" Assembly="VPLookup" %>

<%@ Page Language="C#" EnableEventValidation="false" AutoEventWireup="false" Codebehind="Show-MvwISDCustomerXref-Mobile.aspx.cs" Culture="en-US" MasterPageFile="../Master Pages/Mobile.master" Inherits="VPLookup.UI.Show_MvwISDCustomerXref_Mobile" %>
<%@ Register Tagprefix="VPLookup" TagName="PaginationMobile" Src="../Shared/PaginationMobile.ascx" %>

<%@ Register Tagprefix="Selectors" Namespace="VPLookup" Assembly="VPLookup" %>

<%@ Register Tagprefix="BaseClasses" Namespace="BaseClasses.Web.UI.WebControls" Assembly="BaseClasses" %><asp:Content id="PageSection" ContentPlaceHolderID="PageContent" Runat="server">
    <a id="StartOfPageContent"></a>
    <div id="scrollRegion" class="scrollRegion">              
      
                <table cellpadding="0" cellspacing="0" border="0" style="width: 100%"><tr><td><%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("CancelButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("EditButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("OKButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("SaveAndNewButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("SaveButton"))%>

                        <VPLookup:MvwISDCustomerXrefRecordControl runat="server" id="MvwISDCustomerXrefRecordControl">	<table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td>
                        <table cellpadding="0" cellspacing="0" border="0" width="100%" class="mobileHeader"><tr><td class="mobileHeaderLeft">
                            <asp:ImageButton runat="server" id="CancelButton" causesvalidation="False" commandname="Redirect" imageurl="../Images/MobileButtonBack.png" text="&lt;%# GetResourceValue(&quot;Btn:Back&quot;, &quot;VPLookup&quot;) %>" tooltip="&lt;%# GetResourceValue(&quot;Btn:Back&quot;, &quot;VPLookup&quot;) %>">		
	</asp:ImageButton>
                          </td><td class="mobileHeaderTitle">
                      <asp:Literal runat="server" id="Title" Text="&lt;%#String.Concat(&quot;&lt;span class='mobileFontAdjust80'>&quot;, &quot; Customer&quot;, &quot;&lt;/span>&quot;) %>">	</asp:Literal>
                    </td></tr></table>

                      </td></tr><tr><td>
                      <asp:panel id="CollapsibleRegion" runat="server"><table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td class="mobileBody"><asp:panel id="MvwISDCustomerXrefRecordControlPanel" runat="server"><table class="mobileRecordPanel mobileBody" cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td class="mobileFieldValueOnBottom" colspan="2" style="white-space: nowrap"><b><asp:Literal runat="server" id="CustomerName"></asp:Literal></b></td></tr><tr><td class="mobileFieldLabelOnTop"><asp:Literal runat="server" id="AddressLabel" Text="Address">	</asp:Literal></td><td class="mobileFieldLabelOnTop"></td></tr><tr><td class="mobileFieldValueOnTop" colspan="2" style="white-space: nowrap"><asp:Literal runat="server" id="Address"></asp:Literal>  <br />
<asp:Literal runat="server" id="Address2"></asp:Literal> <br /> 
<asp:Literal runat="server" id="City"></asp:Literal> ,
<asp:Literal runat="server" id="State"></asp:Literal> 
<asp:Literal runat="server" id="Zip"></asp:Literal></td></tr><tr><td class="mobileFieldLabelOnTop"><asp:Literal runat="server" id="VPCustomerLabel" Text="VP Customer">	</asp:Literal></td><td class="mobileFieldLabelOnTop"></td></tr><tr><td class="mobileFieldValueOnBottom"><asp:Literal runat="server" id="VPCustomer"></asp:Literal> </td><td class="mobileFieldValueOnBottom"></td></tr><tr><td class="mobileFieldLabelOnTop"><asp:Literal runat="server" id="CGCCustomerLabel" Text="CGC Customer">	</asp:Literal></td><td class="mobileFieldLabelOnTop"></td></tr><tr><td class="mobileFieldValueOnBottom"><asp:Literal runat="server" id="CGCCustomer"></asp:Literal> </td><td class="mobileFieldValueOnBottom"></td></tr><tr><td class="mobileFieldLabelOnTop"><asp:Literal runat="server" id="AsteaCustomerLabel" Text="Astea Customer">	</asp:Literal></td><td class="mobileFieldLabelOnTop"></td></tr><tr><td class="mobileFieldValueOnBottom"><asp:Literal runat="server" id="AsteaCustomer"></asp:Literal> </td><td class="mobileFieldValueOnBottom"></td></tr><tr><td class="mobileFieldValueOnBottom"></td><td class="mobileFieldValueOnBottom"></td></tr><tr><td class="mobileFieldValueOnBottom"><asp:literal id="CustomerLocation" runat="server"></asp:literal></td><td class="mobileFieldValueOnBottom"></td></tr></table></asp:panel>
</td></tr></table>
</asp:panel>
                      </td></tr></table>
	<asp:hiddenfield id="MvwISDCustomerXrefRecordControl_PostbackTracker" runat="server" />
</VPLookup:MvwISDCustomerXrefRecordControl>

            <%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("SaveButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("SaveAndNewButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("OKButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("EditButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("CancelButton"))%>
</td></tr><tr><td><asp:accordion id="MvwISDCustomerXrefAccordion" runat="server" requireopenedpane="false" suppressheaderpostbacks="true" selectedindex="-1">
      <panes>
          <asp:accordionpane id="MvwISDJobXrefAccordionPane" runat="server">
              <header><table border="0" cellpadding="0" cellspacing="0" style="width: 100%;"><tr><td class="mobileAccordionHeader"><span class="mobileAccordionHeaderTitle">&nbsp;&nbsp;Customer Jobs</span></td></tr></table></header>
              <content><VPLookup:MvwISDJobXrefTableControl runat="server" id="MvwISDJobXrefTableControl">	<table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td width="100%">
                        <VPLookup:PaginationMobile runat="server" id="Pagination"></VPLookup:PaginationMobile>
                      </td></tr><tr><td>
                      <asp:panel id="CollapsibleRegion1" runat="server"><table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td class="mobileFilterArea">
                      <asp:panel id="CollapsibleRegionMobile1" style="display: none; overflow: hidden; height: 0px; width: 96%; padding-left: 2%; padding-right: 2%; margin: 0px;" cssClass="mobileBody" runat="server">
</asp:panel>
                  </td></tr><tr><td class="mobileBodyNoPadding"><table id="MvwISDJobXrefTableControlGrid" cellpadding="0" cellspacing="0" border="0" onkeydown="captureUpDownKey(this, event)" width="100%"><tr><th class="mobileTableCell" colspan="1" style="display:none"><!-- Note: Cell Is Hidden --></th><th class="mobileTableCell" scope="col" style="display:none"><!-- Note: Cell Is Hidden --></th><th class="mobileTableCell" scope="col" style="display:none"><!-- Note: Cell Is Hidden --></th></tr><asp:Repeater runat="server" id="MvwISDJobXrefTableControlRepeater">		<ITEMTEMPLATE>		<VPLookup:MvwISDJobXrefTableControlRow runat="server" id="MvwISDJobXrefTableControlRow">
<tr onclick="RedirectByViewButton(event)"><td class="mobileTableCell" style="display:none;"><!-- Note: Cell Is Hidden --><asp:ImageButton runat="server" id="ViewRowButton" causesvalidation="False" commandname="Redirect" cssclass="button_link" imageurl="../Images/MobileButtonNext.ltr.png" tooltip="&lt;%# GetResourceValue(&quot;Txt:ViewRecord&quot;, &quot;VPLookup&quot;) %>">		
	</asp:ImageButton></td><td class="mobileTableImageCell" colspan="2"><table>
<tr>
<td colspan='2'><b><asp:Literal runat="server" id="VPJobDesc"></asp:Literal></b></td>
</tr>
<tr>
<td>VP Job #&nbsp;&nbsp;</td><td><asp:Literal runat="server" id="VPJob"></asp:Literal> ( <asp:Literal runat="server" id="VPCo"></asp:Literal> )</td>
</tr>
<tr>
<td>CGC Job #&nbsp;&nbsp;</td><td><asp:Literal runat="server" id="CGCJob"></asp:Literal> ( <asp:Literal runat="server" id="CGCCo"></asp:Literal> )</td>
</tr>
<tr>
<td valign='top'>Job Address&nbsp;&nbsp;</td>
<td valign='top'>
<asp:Literal runat="server" id="MailAddress"></asp:Literal> <br />
<asp:Literal runat="server" id="MailAddress2"></asp:Literal> <br />
<asp:Literal runat="server" id="MailCity"></asp:Literal> ,
<asp:Literal runat="server" id="MailState"></asp:Literal> 
<asp:Literal runat="server" id="MailZip"></asp:Literal>
</td>
</tr>
</table></td></tr></VPLookup:MvwISDJobXrefTableControlRow>
</ITEMTEMPLATE>

</asp:Repeater>
</table>
</td></tr></table>
</asp:panel>
                      </td></tr></table>
	<asp:hiddenfield id="MvwISDJobXrefTableControl_PostbackTracker" runat="server" />
</VPLookup:MvwISDJobXrefTableControl>
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
                