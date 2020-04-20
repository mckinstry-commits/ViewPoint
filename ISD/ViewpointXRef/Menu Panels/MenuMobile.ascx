<%@ Control Language="C#" AutoEventWireup="false" Codebehind="MenuMobile.ascx.cs" Inherits="ViewpointXRef.UI.MenuMobile" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Tagprefix="Selectors" Namespace="ViewpointXRef" Assembly="ViewpointXRef" %>

<%@ Register Tagprefix="BaseClasses" Namespace="BaseClasses.Web.UI.WebControls" Assembly="BaseClasses" %><table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td><table cellpadding="0" cellspacing="0" border="0" width="100%"><tr><td colspan="3"><asp:Menu ID="MultiLevelMenu" DataSourceID="SiteMapDataSource1" runat="server" itemwrap="True" DynamicItemFormatString="&lt;div class='mobileMenu' style='width: 96%;'&gt;{0}&lt;/div&gt;" StaticItemFormatString="&lt;div class='mobileMenu' style='width: 96%;'&gt;{0}&lt;/div&gt;" StaticEnableDefaultPopOutImage="False" MaximumDynamicDisplayLevels="100" width="100%" orientation="Vertical"> 
							<StaticMenuItemStyle CssClass="" />
							<DynamicMenuStyle CssClass="mobileSubmenuContainer" />
							<DynamicMenuItemStyle CssClass="" />
						</asp:Menu>
						<asp:SiteMapDataSource ID="SiteMapDataSource1" runat="server" SiteMapProvider="ViewpointXRefMenuMobileElementsProvider" ShowStartingNode="false" />
					</td></tr></table>
</td></tr></table>