SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[vpspPortalSiteDataExport]
(
	@ServerName as varchar(100),
	@Filepath as varchar(100),
    @User as varchar(100),
    @Password as varchar(100),
    @SiteID as varchar(20)
)
AS

DECLARE @Query varchar(2000), @Name varchar(1000)

SET @Query = 'SELECT * FROM ' + @ServerName + '.dbo.pCalendar WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM pPageSiteControls WHERE SiteID = ' + @SiteID + ')'
SET @Name = 'CalendarData' + @SiteID
exec vpspPortalQueryExportBCP @Name, @Query, @Filepath, @User, @Password

SET @Query = 'SELECT * FROM ' + @ServerName + '.dbo.pCalendarEventsToday WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM pPageSiteControls WHERE SiteID = ' + @SiteID + ')'
SET @Name = 'CalendarEventsTodayData' + @SiteID
exec vpspPortalQueryExportBCP @Name, @Query, @Filepath, @User, @Password

SET @Query = 'SELECT * FROM ' + @ServerName + '.dbo.pCameraControl WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM pPageSiteControls WHERE SiteID = ' + @SiteID + ')'
SET @Name = 'CameraControlData' + @SiteID
exec vpspPortalQueryExportBCP @Name, @Query, @Filepath, @User, @Password

SET @Query = 'SELECT * FROM ' + @ServerName + '.dbo.pContactMethods WHERE SiteID = ' + @SiteID 
SET @Name = 'ContactMethodsData' + @SiteID
exec vpspPortalQueryExportBCP @Name, @Query, @Filepath, @User, @Password

SET @Query = 'SELECT * FROM ' + @ServerName + '.dbo.pContacts WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM pPageSiteControls WHERE SiteID = ' + @SiteID + ')'
SET @Name = 'ContactsData' + @SiteID
exec vpspPortalQueryExportBCP @Name, @Query, @Filepath, @User, @Password

SET @Query = 'SELECT * FROM ' + @ServerName + '.dbo.pCustomControl WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM pPageSiteControls WHERE SiteID = ' + @SiteID + ')'
SET @Name = 'CustomControlData' + @SiteID
exec vpspPortalQueryExportBCP @Name, @Query, @Filepath, @User, @Password

SET @Query = 'SELECT * FROM ' + @ServerName + '.dbo.pDirectoryBrowser WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM pPageSiteControls WHERE SiteID = ' + @SiteID + ')'
SET @Name = 'DirectoryBrowserData' + @SiteID
exec vpspPortalQueryExportBCP @Name, @Query, @Filepath, @User, @Password

SET @Query = 'SELECT * FROM ' + @ServerName + '.dbo.pDisplayControl WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM pPageSiteControls WHERE SiteID = ' + @SiteID + ')'
SET @Name = 'DisplayControlData' + @SiteID
exec vpspPortalQueryExportBCP @Name, @Query, @Filepath, @User, @Password

SET @Query = 'SELECT * FROM ' + @ServerName + '.dbo.pForum WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM pPageSiteControls WHERE SiteID = ' + @SiteID + ')'
SET @Name = 'ForumData' + @SiteID
exec vpspPortalQueryExportBCP @Name, @Query, @Filepath, @User, @Password

SET @Query = 'SELECT * FROM ' + @ServerName + '.dbo.pForumViews WHERE ForumID IN (SELECT ForumID FROM pForum WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM pPageSiteControls WHERE SiteID = ' + @SiteID + '))'
SET @Name = 'ForumViewsData' + @SiteID
exec vpspPortalQueryExportBCP @Name, @Query, @Filepath, @User, @Password

SET @Query = 'SELECT * FROM ' + @ServerName + '.dbo.pLinkControl WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM pPageSiteControls WHERE SiteID = ' + @SiteID + ')'
SET @Name = 'LinkControlData' + @SiteID
exec vpspPortalQueryExportBCP @Name, @Query, @Filepath, @User, @Password

SET @Query = 'SELECT * FROM ' + @ServerName + '.dbo.pMenuSiteLinkRoles WHERE SiteID = ' + @SiteID 
SET @Name = 'MenuSiteLinkRolesData' + @SiteID
exec vpspPortalQueryExportBCP @Name, @Query, @Filepath, @User, @Password

SET @Query = 'SELECT * FROM ' + @ServerName + '.dbo.pMenuSiteLinks WHERE SiteID = ' + @SiteID 
SET @Name = 'MenuSiteLinksData' + @SiteID
exec vpspPortalQueryExportBCP @Name, @Query, @Filepath, @User, @Password

SET @Query = 'SELECT * FROM ' + @ServerName + '.dbo.pPageSiteControls WHERE SiteID = ' + @SiteID 
SET @Name = 'PageSiteControlsData' + @SiteID
exec vpspPortalQueryExportBCP @Name, @Query, @Filepath, @User, @Password

SET @Query = 'SELECT * FROM ' + @ServerName + '.dbo.pPageSiteControlSecurity WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM pPageSiteControls WHERE SiteID = ' + @SiteID + ')'
SET @Name = 'PageSiteControlSecurityData' + @SiteID
exec vpspPortalQueryExportBCP @Name, @Query, @Filepath, @User, @Password

SET @Query = 'SELECT * FROM ' + @ServerName + '.dbo.pPageSiteTemplates WHERE SiteID = ' + @SiteID 
SET @Name = 'PageSiteTemplatesData' + @SiteID
exec vpspPortalQueryExportBCP @Name, @Query, @Filepath, @User, @Password

SET @Query = 'SELECT * FROM ' + @ServerName + '.dbo.pSiteAttachmentBinaries WHERE SiteAttachmentID IN (SELECT SiteAttachmentID FROM pSiteAttachments WHERE SiteID = ' + @SiteID + ')'
SET @Name = 'SiteAttachmentBinariesData' + @SiteID
exec vpspPortalQueryExportBCP @Name, @Query, @Filepath, @User, @Password

SET @Query = 'SELECT * FROM ' + @ServerName + '.dbo.pSiteAttachments WHERE SiteID = ' + @SiteID 
SET @Name = 'SiteAttachmentsData' + @SiteID
exec vpspPortalQueryExportBCP @Name, @Query, @Filepath, @User, @Password

SET @Query = 'SELECT * FROM ' + @ServerName + '.dbo.pSiteFooterLinks WHERE SiteID = ' + @SiteID 
SET @Name = 'SiteFooterLinksData' + @SiteID
exec vpspPortalQueryExportBCP @Name, @Query, @Filepath, @User, @Password

SET @Query = 'SELECT * FROM ' + @ServerName + '.dbo.pSites WHERE SiteID = ' + @SiteID 
SET @Name = 'SitesData' + @SiteID
exec vpspPortalQueryExportBCP @Name, @Query, @Filepath, @User, @Password

SET @Query = 'SELECT * FROM ' + @ServerName + '.dbo.pUserSites WHERE SiteID = ' + @SiteID 
SET @Name = 'UserSitesData' + @SiteID
exec vpspPortalQueryExportBCP @Name, @Query, @Filepath, @User, @Password




GO
GRANT EXECUTE ON  [dbo].[vpspPortalSiteDataExport] TO [VCSPortal]
GO
