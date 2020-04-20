<%-- This default page is used in non-SharePoint environments. DefaultSP.aspx is used when deployed to SharePoint.   
When a SharePoint deployment solution is generated, this file is renamed to Default_original.aspx and DefaultSP.aspx is renamed to Default.aspx --%>

<%@ Page Language="C#" AutoEventWireup="true" MasterPageFile="" %>
<%@ Register Tagprefix="BaseClasses" Namespace="BaseClasses.Web.UI.WebControls" Assembly="BaseClasses" %>
<%@ Import NameSpace="BaseClasses.Configuration" %>
<asp:Content id="PageTitleContent_PlaceHolderMain" ContentPlaceHolderID="PlaceHolderMain" runat="server">

<script runat="server" language="C#">
    private void Page_PreInit(object sender, System.EventArgs e)
    {
        try {
            //Check if SharePoint context is present and if yes set master page to SharePoint's default.
            //This is required to properly load menu control for application running under low permissions account!
            if ((Microsoft.SharePoint.SPContext.Current != null)) {
                this.MasterPageFile = Microsoft.SharePoint.SPContext.Current.Web.MasterUrl;
            }
            else {
                this.MasterPageFile = "/Master Pages/SharePointMaster.master";
            }
            string rootPath = ApplicationSettings.Current.AppRootPath;
        }
        catch (Exception ex) {
            this.MasterPageFile = "/Master Pages/SharePointMaster.master";
        }
    }
    private void Page_PreRenderComplete(object sender, System.EventArgs e)
    {
        //First initialize SharePointUtils
        if (ApplicationSettings.Current.CurrentSharePointFunctions == null) {
            ApplicationSettings.Current.CurrentSharePointFunctions = new SharePointUtils();
        }
        //Now call AppRootPath which will be initializaed to correct path in _layouts folder
        string txt = ApplicationSettings.Current.AppRootPath;
        //Redirect to application's default page which is set in the web.config. If you need to create default page with different page to
        //redirect then simply replace 'ApplicationSettings.Current.DefaultPageUrl' with url of your choice
	    BaseClasses.Web.UI.BasePage.RedirectToDefaultPage(this.Request, this.Response);
    }
</script>
	<title>Default Page</title>			      

<asp:Menu ID="MenuViewpointXRefMenuElementsProvider" DataSourceID="DataSourceViewpointXRefMenuElementsProvider" runat="server" StaticEnableDefaultPopOutImage="False" MaximumDynamicDisplayLevels="100" orientation="Horizontal" />
<asp:SiteMapDataSource ID="DataSourceViewpointXRefMenuElementsProvider" runat="server" SiteMapProvider="ViewpointXRefMenuElementsProvider" ShowStartingNode="false" />
<asp:Menu ID="MenuViewpointXRefMenuMobileElementsProvider" DataSourceID="DataSourceViewpointXRefMenuMobileElementsProvider" runat="server" StaticEnableDefaultPopOutImage="False" MaximumDynamicDisplayLevels="100" orientation="Horizontal" />
<asp:SiteMapDataSource ID="DataSourceViewpointXRefMenuMobileElementsProvider" runat="server" SiteMapProvider="ViewpointXRefMenuMobileElementsProvider" ShowStartingNode="false" /></asp:Content>
