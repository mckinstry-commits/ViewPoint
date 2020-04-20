<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>
<%@ Register Tagprefix="Selectors" Namespace="ViewpointXRef" Assembly="ViewpointXRef" %>

<%@ Control Language="C#" AutoEventWireup="false" Codebehind="Menu.ascx.cs" Inherits="ViewpointXRef.UI.Menu" %>
<%@ Register Tagprefix="BaseClasses" Namespace="BaseClasses.Web.UI.WebControls" Assembly="BaseClasses" %><table cellpadding="0" cellspacing="0" border="0"><tr><td><table cellpadding="0" cellspacing="0" border="0" class="ISDMenu"><tr><td colspan="3">
						<asp:Menu ID="MultiLevelMenu" DataSourceID="SiteMapDataSource1" runat="server" StaticEnableDefaultPopOutImage="False" MaximumDynamicDisplayLevels="100" orientation="Horizontal">
						<StaticMenuItemStyle CssClass="ms-rteImage-4" ItemSpacing="0px" />
						<StaticSelectedStyle CssClass="ms-rteImage-4" />
						<StaticHoverStyle CssClass="ms-rteImage-4" />
						<DynamicMenuStyle CssClass="ms-topNavHover" BorderWidth="1px" />
						<DynamicMenuItemStyle CssClass="ms-topNavFlyOuts" />
						<DynamicHoverStyle CssClass="ms-topNavFlyOutsHover" />
						<DynamicSelectedStyle CssClass="ms-topNavFlyOutsSelected" />
						</asp:Menu>
						<asp:SiteMapDataSource ID="SiteMapDataSource1" runat="server" SiteMapProvider="ViewpointXRefMenuElementsProvider" ShowStartingNode="false" />
					</td></tr></table>
</td></tr></table>