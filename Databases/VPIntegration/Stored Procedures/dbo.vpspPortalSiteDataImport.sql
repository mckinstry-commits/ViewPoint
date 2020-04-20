SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE   procedure [dbo].[vpspPortalSiteDataImport]
(
	@ServerName as varchar(100),
	@Filepath as varchar(100),
    @SiteID as varchar(20)
)
AS

PRINT 'Start'

DECLARE @Query varchar(1000), @Name varchar(1000), @TableName varchar(50), @ExecuteString as nvarchar(1000)

SET @Query = 'DELETE FROM ' + @ServerName + '.dbo.pCalendarEventsToday WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM ' + @ServerName + '.dbo.pPageSiteControls WHERE SiteID = ' + @SiteID + ')'
Select @ExecuteString = CAST(@Query AS NVarchar(1000))
exec sp_executesql @ExecuteString

PRINT 'Delete CalendarEventsToday'

SET @Query = 'DELETE FROM ' + @ServerName + '.dbo.pCalendar WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM ' + @ServerName + '.dbo.pPageSiteControls WHERE SiteID = ' + @SiteID + ')'
Select @ExecuteString = CAST(@Query AS NVarchar(1000))
exec sp_executesql @ExecuteString

PRINT 'Delete pCalendar'

SET @Query = 'DELETE FROM ' + @ServerName + '.dbo.pCameraControl WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM ' + @ServerName + '.dbo.pPageSiteControls WHERE SiteID = ' + @SiteID + ')'
Select @ExecuteString = CAST(@Query AS NVarchar(1000))
exec sp_executesql @ExecuteString


SET @Query = 'DELETE FROM ' + @ServerName + '.dbo.pCameraControl WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM ' + @ServerName + '.dbo.pPageSiteControls WHERE PageSiteTemplateID IN (SELECT PageSiteTemplateID FROM ' + @ServerName + '.dbo.pPageSiteTemplates WHERE SiteID  = ' + @SiteID + '))'
Select @ExecuteString = CAST(@Query AS NVarchar(1000))
exec sp_executesql @ExecuteString


SET @Query = 'DELETE FROM ' + @ServerName + '.dbo.pContactMethods WHERE SiteID = ' + @SiteID 
Select @ExecuteString = CAST(@Query AS NVarchar(1000))
exec sp_executesql @ExecuteString

SET @Query = 'DELETE FROM ' + @ServerName + '.dbo.pContacts WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM ' + @ServerName + '.dbo.pPageSiteControls WHERE SiteID = ' + @SiteID + ')'
Select @ExecuteString = CAST(@Query AS NVarchar(1000))
exec sp_executesql @ExecuteString

SET @Query = 'DELETE FROM ' + @ServerName + '.dbo.pCustomControl WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM ' + @ServerName + '.dbo.pPageSiteControls WHERE SiteID = ' + @SiteID + ')'
Select @ExecuteString = CAST(@Query AS NVarchar(1000))
exec sp_executesql @ExecuteString

SET @Query = 'DELETE FROM ' + @ServerName + '.dbo.pDirectoryBrowser WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM ' + @ServerName + '.dbo.pPageSiteControls WHERE SiteID = ' + @SiteID + ')'
Select @ExecuteString = CAST(@Query AS NVarchar(1000))
exec sp_executesql @ExecuteString

SET @Query = 'DELETE FROM ' + @ServerName + '.dbo.pDisplayControl WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM ' + @ServerName + '.dbo.pPageSiteControls WHERE SiteID = ' + @SiteID + ')'
Select @ExecuteString = CAST(@Query AS NVarchar(1000))
exec sp_executesql @ExecuteString

SET @Query = 'DELETE FROM ' + @ServerName + '.dbo.pForumViews WHERE ForumID IN (SELECT ForumID FROM ' + @ServerName + '.dbo.pForum WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM ' + @ServerName + '.dbo.pPageSiteControls WHERE SiteID = ' + @SiteID + '))'
Select @ExecuteString = CAST(@Query AS NVarchar(1000))
exec sp_executesql @ExecuteString

SET @Query = 'DELETE FROM ' + @ServerName + '.dbo.pForum WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM ' + @ServerName + '.dbo.pPageSiteControls WHERE SiteID = ' + @SiteID + ')'
Select @ExecuteString = CAST(@Query AS NVarchar(1000))
exec sp_executesql @ExecuteString

SET @Query = 'DELETE FROM ' + @ServerName + '.dbo.pLinkControl WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM ' + @ServerName + '.dbo.pPageSiteControls WHERE SiteID = ' + @SiteID + ')'
Select @ExecuteString = CAST(@Query AS NVarchar(1000))
exec sp_executesql @ExecuteString

SET @Query = 'DELETE FROM ' + @ServerName + '.dbo.pMenuSiteLinkRoles WHERE SiteID = ' + @SiteID 
Select @ExecuteString = CAST(@Query AS NVarchar(1000))
exec sp_executesql @ExecuteString

SET @Query = 'DELETE FROM ' + @ServerName + '.dbo.pMenuSiteLinks WHERE SiteID = ' + @SiteID 
Select @ExecuteString = CAST(@Query AS NVarchar(1000))
exec sp_executesql @ExecuteString

PRINT 'MenuSiteLinks'

SET @Query = 'DELETE FROM ' + @ServerName + '.dbo.pPageSiteControlSecurity WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM ' + @ServerName + '.dbo.pPageSiteControls WHERE SiteID = ' + @SiteID + ')'
Select @ExecuteString = CAST(@Query AS NVarchar(1000))
exec sp_executesql @ExecuteString

SET @Query = 'DELETE FROM ' + @ServerName + '.dbo.pPageSiteControlSecurity WHERE PageSiteControlID IN (SELECT PageSiteControlID FROM ' + @ServerName + '.dbo.pPageSiteControls WHERE PageSiteTemplateID IN (SELECT PageSiteTemplateID FROM ' + @ServerName + '.dbo.pPageSiteTemplates WHERE SiteID  = ' + @SiteID + '))'
Select @ExecuteString = CAST(@Query AS NVarchar(1000))
exec sp_executesql @ExecuteString

PRINT 'PageSiteControlSecurity'

SET @Query = 'DELETE FROM ' + @ServerName + '.dbo.pPageSiteControls WHERE SiteID = ' + @SiteID 
Select @ExecuteString = CAST(@Query AS NVarchar(1000))
exec sp_executesql @ExecuteString

SET @Query = 'DELETE FROM ' + @ServerName + '.dbo.pPageSiteControls WHERE PageSiteTemplateID IN (SELECT PageSiteTemplateID FROM ' + @ServerName + '.dbo.pPageSiteTemplates WHERE SiteID  = ' + @SiteID + ')'
Select @ExecuteString = CAST(@Query AS NVarchar(1000))
exec sp_executesql @ExecuteString

PRINT 'PageSiteControls'

SET @Query = 'UPDATE ' + @ServerName + '.dbo.pSites SET PageSiteTemplateID = NULL WHERE PageSiteTemplateID IN (SELECT PageSiteTemplateID FROM ' + @ServerName + '.dbo.pPageSiteTemplates WHERE SiteID  = ' + @SiteID + ')'
Select @ExecuteString = CAST(@Query AS NVarchar(1000))
exec sp_executesql @ExecuteString

SET @Query = 'DELETE FROM ' + @ServerName + '.dbo.pPageSiteTemplates WHERE SiteID = ' + @SiteID 
Select @ExecuteString = CAST(@Query AS NVarchar(1000))
exec sp_executesql @ExecuteString

PRINT 'PageSiteTemplate'

SET @Query = 'DELETE FROM ' + @ServerName + '.dbo.pSiteAttachmentBinaries WHERE SiteAttachmentID IN (SELECT SiteAttachmentID FROM ' + @ServerName + '.dbo.pSiteAttachments WHERE SiteID = ' + @SiteID + ')'
Select @ExecuteString = CAST(@Query AS NVarchar(1000))
exec sp_executesql @ExecuteString

PRINT 'SiteAttachmentBinaries'

SET @Query = 'UPDATE ' + @ServerName + '.dbo.pSites SET SiteAttachmentID = NULL WHERE SiteAttachmentID IN (SELECT SiteAttachmentID FROM ' + @ServerName + '.dbo.pSiteAttachments WHERE SiteID  = ' + @SiteID + ')'
Select @ExecuteString = CAST(@Query AS NVarchar(1000))
exec sp_executesql @ExecuteString

SET @Query = 'DELETE FROM ' + @ServerName + '.dbo.pSiteAttachments WHERE SiteID = ' + @SiteID 
Select @ExecuteString = CAST(@Query AS NVarchar(1000))
exec sp_executesql @ExecuteString

PRINT 'SiteAttachments'

SET @Query = 'DELETE FROM ' + @ServerName + '.dbo.pSiteFooterLinks WHERE SiteID = ' + @SiteID 
Select @ExecuteString = CAST(@Query AS NVarchar(1000))
exec sp_executesql @ExecuteString

PRINT 'SiteFooterLinks'

SET @Query = 'DELETE FROM ' + @ServerName + '.dbo.pUserSites WHERE SiteID = ' + @SiteID 
Select @ExecuteString = CAST(@Query AS NVarchar(1000))
exec sp_executesql @ExecuteString

PRINT 'UserSites'

PRINT 'Still Deleting'

SET @Query = 'UPDATE ' + @ServerName + '.dbo.pUsers SET DefaultSiteID = NULL WHERE DefaultSiteID = ' + @SiteID
Select @ExecuteString = CAST(@Query AS NVarchar(1000))
exec sp_executesql @ExecuteString

SET @Query = 'DELETE FROM ' + @ServerName + '.dbo.pSites WHERE SiteID = ' + @SiteID 
Select @ExecuteString = CAST(@Query AS NVarchar(1000))
exec sp_executesql @ExecuteString

PRINT 'Sites'
PRINT 'Site DATA Deleted'


PRINT 'Import'
SET @Name = @Filepath + 'SitesData' + @SiteID + '.bcp'
SET @TableName = @ServerName + '.dbo.pSites'
exec vpspPortalImportBCP @TableName,  @Name

SET @Name = @Filepath + 'UserSitesData' + @SiteID + '.bcp'
SET @TableName = @ServerName + '.dbo.pUserSites'
exec vpspPortalImportBCP @TableName,  @Name

SET @Name = @Filepath + 'SiteFooterLinksData' + @SiteID + '.bcp'
SET @TableName = @ServerName + '.dbo.pSiteFooterLinks'
exec vpspPortalImportBCP @TableName,  @Name

SET @Name = @Filepath + 'SiteAttachmentsData' + @SiteID + '.bcp'
SET @TableName = @ServerName + '.dbo.pSiteAttachments'
exec vpspPortalImportBCP @TableName,  @Name

SET @Name = @Filepath + 'SiteAttachmentBinariesData' + @SiteID + '.bcp'
SET @TableName = @ServerName + '.dbo.pSiteAttachmentBinaries'
exec vpspPortalImportBCP @TableName,  @Name

SET @Name = @Filepath + 'PageSiteTemplatesData' + @SiteID + '.bcp'
SET @TableName = @ServerName + '.dbo.pPageSiteTemplates'
exec vpspPortalImportBCP @TableName,  @Name

SET @Name = @Filepath + 'PageSiteControlsData' + @SiteID + '.bcp'
SET @TableName = @ServerName + '.dbo.pPageSiteControls'
exec vpspPortalImportBCP @TableName,  @Name

SET @Name = @Filepath + 'PageSiteControlSecurityData' + @SiteID + '.bcp'
SET @TableName = @ServerName + '.dbo.pPageSiteControlSecurity'
exec vpspPortalImportBCP @TableName,  @Name

SET @Name = @Filepath + 'MenuSiteLinksData' + @SiteID + '.bcp'
SET @TableName = @ServerName + '.dbo.pMenuSiteLinks'
exec vpspPortalImportBCP @TableName,  @Name

SET @Name = @Filepath + 'MenuSiteLinkRolesData' + @SiteID + '.bcp'
SET @TableName = @ServerName + '.dbo.pMenuSiteLinkRoles'
exec vpspPortalImportBCP @TableName,  @Name

SET @Name = @Filepath + 'LinkControlData' + @SiteID + '.bcp'
SET @TableName = @ServerName + '.dbo.pLinkControl'
exec vpspPortalImportBCP @TableName,  @Name

SET @Name = @Filepath + 'ForumData' + @SiteID + '.bcp'
SET @TableName = @ServerName + '.dbo.pForum'
exec vpspPortalImportBCP @TableName,  @Name

SET @Name = @Filepath + 'ForumViewsData' + @SiteID + '.bcp'
SET @TableName = @ServerName + '.dbo.pForumViews'
exec vpspPortalImportBCP @TableName,  @Name

SET @Name = @Filepath + 'CameraControlData' + @SiteID + '.bcp'
SET @TableName = @ServerName + '.dbo.pCameraControl'
exec vpspPortalImportBCP @TableName,  @Name

SET @Name = @Filepath + 'ContactMethodsData' + @SiteID + '.bcp'
SET @TableName = @ServerName + '.dbo.pContactMethods'
exec vpspPortalImportBCP @TableName,  @Name

SET @Name = @Filepath + 'ContactsData' + @SiteID + '.bcp'
SET @TableName = @ServerName + '.dbo.pContacts'
exec vpspPortalImportBCP @TableName,  @Name

SET @Name = @Filepath + 'CustomControlData' + @SiteID + '.bcp'
SET @TableName = @ServerName + '.dbo.pCustomControl'
exec vpspPortalImportBCP @TableName,  @Name

SET @Name = @Filepath + 'DirectoryBrowserData' + @SiteID + '.bcp'
SET @TableName = @ServerName + '.dbo.pDirectoryBrowser'
exec vpspPortalImportBCP @TableName,  @Name

SET @Name = @Filepath + 'DisplayControlData' + @SiteID + '.bcp'
SET @TableName = @ServerName + '.dbo.pDisplayControl'
exec vpspPortalImportBCP @TableName,  @Name

SET @Name = @Filepath + 'CalendarData' + @SiteID + '.bcp'
SET @TableName = @ServerName + '.dbo.pCalendar'
exec vpspPortalImportBCP @TableName,  @Name

SET @Name = @Filepath + 'CalendarEventsTodayData' + @SiteID + '.bcp'
SET @TableName = @ServerName + '.dbo.pCalendarEventsToday'
exec vpspPortalImportBCP @TableName,  @Name


PRINT 'Done'



GO
GRANT EXECUTE ON  [dbo].[vpspPortalSiteDataImport] TO [VCSPortal]
GO
