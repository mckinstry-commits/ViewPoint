﻿<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Control Language="C#" AutoEventWireup="false" Codebehind="DatePaginationMobile.ascx.cs" Inherits="VPLookup.UI.DatePaginationMobile" %>
<%@ Register Tagprefix="VPLookup" TagName="ThemeButtonMobile" Src="../Shared/ThemeButtonMobile.ascx" %>

<%@ Register Tagprefix="Selectors" Namespace="VPLookup" Assembly="VPLookup" %>

<%@ Register Tagprefix="BaseClasses" Namespace="BaseClasses.Web.UI.WebControls" Assembly="BaseClasses" %>
    <a id="StartOfPageContent"></a>
    
                <table cellpadding="0" cellspacing="0" border="0"><tr><td style="text-align:right;"><VPLookup:ThemeButtonMobile runat="server" id="_PreviousPageInterval" button-causesvalidation="False" button-commandname="PreviousPageInterval" postback="False"></VPLookup:ThemeButtonMobile></td><td class="mobileFieldValueOnBottom" width="300px" style="text-align:center;"><asp:dropdownlist id="_IntervalDropdown" runat="server" cssclass="mobileFieldInput" autopostback="True" /></td><td style="text-align:left;"><VPLookup:ThemeButtonMobile runat="server" id="_NextPageInterval" button-causesvalidation="False" button-commandname="NextPageInterval" postback="False"></VPLookup:ThemeButtonMobile></td><td style="text-align:left;" nowrap="nowrap"><asp:Literal runat="server" id="_StartDate1" visible="False">	</asp:Literal></td></tr></table>
    
    <div id="detailPopup" class="detailRolloverPopup" onmouseout="detailRolloverPopupClose();" onmouseover="clearTimeout(gPopupTimer);"></div>
    <asp:ValidationSummary id="ValidationSummary1" ShowMessageBox="true" ShowSummary="false" runat="server"></asp:ValidationSummary>

                