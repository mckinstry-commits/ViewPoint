<%@ Register Tagprefix="VPLookup" Namespace="VPLookup.UI.Controls.Show_MvwISDVendorXref_Mobile" Assembly="VPLookup" %>

<%@ Page Language="C#" EnableEventValidation="false" AutoEventWireup="false" Codebehind="Show-MvwISDVendorXref-Mobile.aspx.cs" Culture="en-US" MasterPageFile="../Master Pages/Mobile.master" Inherits="VPLookup.UI.Show_MvwISDVendorXref_Mobile" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Tagprefix="Selectors" Namespace="VPLookup" Assembly="VPLookup" %>

<%@ Register Tagprefix="BaseClasses" Namespace="BaseClasses.Web.UI.WebControls" Assembly="BaseClasses" %><asp:Content id="PageSection" ContentPlaceHolderID="PageContent" Runat="server">
    <a id="StartOfPageContent"></a>
    <div id="scrollRegion" class="scrollRegion">              
      
                <table cellpadding="0" cellspacing="0" border="0" style="width: 100%"><tr><td><%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("CancelButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("EditButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("OKButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("SaveAndNewButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureBeginTag(FindControlRecursively("SaveButton"))%>

                        <VPLookup:MvwISDVendorXrefRecordControl runat="server" id="MvwISDVendorXrefRecordControl">	<table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td>
                        <table cellpadding="0" cellspacing="0" border="0" width="100%" class="mobileHeader"><tr><td class="mobileHeaderLeft">
                            <asp:ImageButton runat="server" id="CancelButton" causesvalidation="False" commandname="Redirect" imageurl="../Images/MobileButtonBack.png" text="&lt;%# GetResourceValue(&quot;Btn:Back&quot;, &quot;VPLookup&quot;) %>" tooltip="&lt;%# GetResourceValue(&quot;Btn:Back&quot;, &quot;VPLookup&quot;) %>">		
	</asp:ImageButton>
                          </td><td class="mobileHeaderTitle">
                      <asp:Literal runat="server" id="Title" Text="&lt;%#String.Concat(&quot;&lt;span class='mobileFontAdjust90'>&quot;, &quot; Vendor&quot;, &quot;&lt;/span>&quot;) %>">	</asp:Literal>
                    </td><td class="mobileHeaderOptions"></td><td class="mobileHeaderRight"></td></tr></table>

                      </td></tr><tr><td>
                      <asp:panel id="CollapsibleRegion" runat="server"><table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td class="mobileBody"><asp:panel id="MvwISDVendorXrefRecordControlPanel" runat="server"><table class="mobileRecordPanel mobileBody" cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td class="mobileTableCell" colspan="2"><b><asp:Literal runat="server" id="VendorName"></asp:Literal></b></td></tr><tr><td class="mobileFieldLabelOnTop"><asp:Literal runat="server" id="VendorGroupLabel" Text="Vendor Group">	</asp:Literal></td><td class="mobileTableCell" style="text-align:left;"><asp:Literal runat="server" id="VendorGroup"></asp:Literal> </td></tr><tr><td class="mobileFieldLabelOnTop"><asp:Literal runat="server" id="IsSubcontractorLabel" Text="Is Subcontractor">	</asp:Literal></td><td class="mobileTableCell"><asp:Literal runat="server" id="IsSubcontractor"></asp:Literal></td></tr><tr><td class="mobileFieldLabelOnTop"><asp:Literal runat="server" id="VPVendorLabel" Text="VP Vendor">	</asp:Literal></td><td class="mobileTableCell"><asp:Literal runat="server" id="VPVendor"></asp:Literal></td></tr><tr><td class="mobileFieldLabelOnTop"><asp:Literal runat="server" id="CGCVendorLabel" Text="CGC Vendor">	</asp:Literal></td><td class="mobileTableCell"><asp:Literal runat="server" id="CGCVendor"></asp:Literal></td></tr><tr><td class="mobileFieldLabelOnTop" colspan="2"><asp:Literal runat="server" id="AddressLabel" Text="Address">	</asp:Literal></td></tr><tr><td class="mobileTableCell" colspan="2" style="text-align:left;"><asp:Literal runat="server" id="Address"></asp:Literal>  <br />
<asp:Literal runat="server" id="Address2"></asp:Literal> <br /> 
<asp:Literal runat="server" id="City"></asp:Literal> ,
<asp:Literal runat="server" id="State"></asp:Literal> 
<asp:Literal runat="server" id="Zip"></asp:Literal></td></tr></table></asp:panel>
</td></tr></table>
</asp:panel>
                      </td></tr></table>
	<asp:hiddenfield id="MvwISDVendorXrefRecordControl_PostbackTracker" runat="server" />
</VPLookup:MvwISDVendorXrefRecordControl>

            <%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("SaveButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("SaveAndNewButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("OKButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("EditButton"))%>
<%= SystemUtils.GenerateEnterKeyCaptureEndTag(FindControlRecursively("CancelButton"))%>
</td></tr></table>
      
    </div>
    <div id="detailPopup" class="detailRolloverPopup" onmouseout="detailRolloverPopupClose();" onmouseover="clearTimeout(gPopupTimer);"></div>
                   <div class="QDialog" id="dialog" style="display:none;">
                          <iframe id="QuickPopupIframe" style="width:100%;height:100%;border:none"></iframe>
                   </div>                  
    <asp:ValidationSummary id="ValidationSummary1" ShowMessageBox="true" ShowSummary="false" runat="server"></asp:ValidationSummary>
</asp:Content>
                