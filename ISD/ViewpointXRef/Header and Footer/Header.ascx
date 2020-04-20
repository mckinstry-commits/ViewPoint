<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Tagprefix="Selectors" Namespace="ViewpointXRef" Assembly="ViewpointXRef" %>

<%@ Control Language="C#" AutoEventWireup="false" Codebehind="Header.ascx.cs" Inherits="ViewpointXRef.UI.Header" %>
<%@ Register Tagprefix="BaseClasses" Namespace="BaseClasses.Web.UI.WebControls" Assembly="BaseClasses" %><table cellpadding="0" cellspacing="0" border="0" width="100%" class="logoBG"><tr><td style="vertical-align:top;"><asp:HyperLink runat="server" id="_SkipNavigationLinks" cssclass="skipNavigationLinks" navigateurl="#StartOfPageContent" text="&lt;%# GetResourceValue(&quot;Txt:SkipNavigation&quot;, &quot;ViewpointXRef&quot;) %>" tooltip="&lt;%# GetResourceValue(&quot;Txt:SkipNavigation&quot;, &quot;ViewpointXRef&quot;) %>">		
	</asp:HyperLink></td><td style="text-align:right; vertical-align:top;"><table cellpadding="0" cellspacing="0" border="0"><tr><td><table cellpadding="0" cellspacing="0" border="0"><tr><td style="width:100%;"></td><td><asp:Image runat="server" id="_LeftImage" alt="" height="23" imageurl="../Images/SignInBarL.gif" width="36">		
	</asp:Image></td><td class="signInBar"><asp:dropdownlist id="LanguageSelector" runat="server" cssclass="Filter_Input" AutoPostBack="true"></asp:dropdownlist></td><td class="signInBar"><asp:Image runat="server" id="_Divider1" alt="" imageurl="../Images/SignInBarDivider.gif">		
	</asp:Image></td><td class="signInBar"><asp:dropdownlist id="ThemeSelector" runat="server" cssclass="Filter_Input" AutoPostBack="true"></asp:dropdownlist></td><td class="signInBar"><asp:Image runat="server" id="_Divider0" alt="" imageurl="../Images/SignInBarDivider.gif">		
	</asp:Image></td><td class="signInBar"><asp:LinkButton runat="server" id="_SignIn" causesvalidation="False" commandname="ShowSignIn" tooltip="SignIn">		
	</asp:LinkButton></td><td class="signInBar"><asp:ImageButton runat="server" id="_SIOImage" alt="SignInButton" causesvalidation="False" commandname="ShowSIOImage" imageurl="../Images/SignInBarSignIn.gif">		
	</asp:ImageButton></td><td class="signInBar"><asp:Image runat="server" id="_Divider2" alt="" imageurl="../Images/SignInBarDivider.gif">		
	</asp:Image></td><td class="signInBar"><a href="javascript:printPage();" /><asp:Image runat="server" id="_SignInBarPrintButton" alt="Print" imageurl="../Images/SignInBarPrint.gif" onmouseout="this.src='../Images/SignInBarPrint.gif';" onmouseover="this.src='../Images/SignInBarPrintOver.gif';" tooltip="&lt;%# GetResourceValue(&quot;Txt:PrintPage&quot;, &quot;ViewpointXRef&quot;) %>" style="border:0px;">		
	</asp:Image></td><td><asp:Image runat="server" id="_RightImage" alt="" height="23" imageurl="../Images/SignInBarR.gif" width="36">		
	</asp:Image></td></tr><tr><td></td><td></td><td class="signInBarStatus" colspan="8"><asp:Label runat="server" id="_UserStatusLbl">	</asp:Label></td></tr></table>
</td></tr></table>
</td></tr></table>