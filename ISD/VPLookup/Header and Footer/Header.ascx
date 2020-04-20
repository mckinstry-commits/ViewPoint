﻿<%@ Control Language="C#" AutoEventWireup="false" Codebehind="Header.ascx.cs" Inherits="VPLookup.UI.Header" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Tagprefix="Selectors" Namespace="VPLookup" Assembly="VPLookup" %>

<%@ Register Tagprefix="BaseClasses" Namespace="BaseClasses.Web.UI.WebControls" Assembly="BaseClasses" %><table cellpadding="0" cellspacing="0" border="0" width="100%" class="logoBG"><tr><td class="pHeaderT" colspan="3"><asp:HyperLink runat="server" id="_SkipNavigationLinks" cssclass="skipNavigationLinks" navigateurl="#StartOfPageContent" text="&lt;%# GetResourceValue(&quot;Txt:SkipNavigation&quot;, &quot;VPLookup&quot;) %>" tooltip="&lt;%# GetResourceValue(&quot;Txt:SkipNavigation&quot;, &quot;VPLookup&quot;) %>">		
	</asp:HyperLink></td><td class="pHeaderT"></td><td class="pHeaderT"></td></tr><tr><td class="pHeaderL" colspan="2"><span style="font-size:14pt;color:White"><b>McKinstry Viewpoint Reference</b></span></td><td class="pHeaderR"><table cellpadding="0" cellspacing="0" border="0"><tr><td><table cellpadding="0" cellspacing="0" border="0"><tr><td class="signInBar"><asp:Label runat="server" id="_UserStatusLbl">	</asp:Label></td><td class="signInBar"></td><td class="signInBar"><div onclick="return ISD_ModernButtonClick(this,event);" /><asp:ImageButton runat="server" id="_HeaderSettings" alt="&lt;%# GetResourceValue(&quot;Btn:Settings&quot;, &quot;VPLookup&quot;) %>" causesvalidation="False" commandname="Custom" imageurl="../Images/ButtonOptions.png" onclientclick="return ISD_ShowPopupPanel('languagePanel','_HeaderSettings',this);" onmouseout="this.src='../Images/ButtonOptions.png'" onmouseover="this.src='../Images/ButtonOptionsOver.png'" tooltip="&lt;%# GetResourceValue(&quot;Btn:Settings&quot;, &quot;VPLookup&quot;) %>">		
	</asp:ImageButton></td><td class="signInBar"><asp:LinkButton runat="server" id="_SignIn" causesvalidation="False" commandname="ShowSignIn" tooltip="SignIn">		
	</asp:LinkButton></td><td>&nbsp;</td></tr></table>
</td></tr></table>
</td><td class="pHeaderR"></td><td class="pHeaderR"><asp:Image runat="server" id="_Logo" alt="&lt;%# GetResourceValue(&quot;Txt:PageHeader&quot;, &quot;VPLookup&quot;) %>" imageurl="../Images/Logo.gif" visible="False" style="border-width:0px;">		
	</asp:Image></td></tr><tr><td colspan="3"><div id="languagePanel" class="popupWrapper" runat="server"><table cellpadding="0" cellspacing="0" border="0"><tr><td class="popupTableCellValue" style="text-align: right"><input type="image" src="../Images/closeButton.gif" onmouseover="this.src='../Images/closeButtonOver.gif'" onmouseout="this.src='../Images/closeButton.gif'" alt="" onclick="ISD_HidePopupPanel();return false;" align="top" /><br /></td></tr><tr><td class="popupTableCellValue"><asp:dropdownlist id="LanguageSelector" runat="server" cssclass="Filter_Input" AutoPostBack="true"></asp:dropdownlist></td></tr><tr><td class="popupTableCellValue"><asp:dropdownlist id="ThemeSelector" runat="server" cssclass="Filter_Input" AutoPostBack="true"></asp:dropdownlist></td></tr></table>
</div></td><td></td><td></td></tr></table>