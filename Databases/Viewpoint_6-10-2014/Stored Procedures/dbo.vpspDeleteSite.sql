SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE               PROCEDURE [dbo].[vpspDeleteSite]
(
	@SiteID int
)
AS
SET NOCOUNT OFF;
--Delete the Menu, Pages and controls for the Site
exec vpspDeleteSiteMenuAndControls @SiteID

--Delete all the SiteAttachment binaries for the Site
DELETE pSiteAttachmentBinaries WHERE SiteAttachmentID IN (SELECT SiteAttachmentID FROM pSiteAttachments WHERE SiteID = @SiteID)
Print 'Deleted Site Attachment Binaries'

--Remove the Attachment from the Site Header
UPDATE pSites SET SiteAttachmentID = NULL WHERE SiteID = @SiteID

--Delete all of the SiteAttachements for the Site
DELETE pSiteAttachments WHERE SiteID = @SiteID
Print 'Deleted Site Attachments'

--Delete all the SiteFooterLinks for the Site
DELETE pSiteFooterLinks WHERE SiteID = @SiteID
Print 'Deleted Footer Links'

--Delete all the User Sites for the Site
DELETE pUserSites WHERE SiteID = @SiteID
Print 'Deleted User Sites'

--Update any Users who had this Site as their Default Site with the Welcome Site as default
UPDATE pUsers SET DefaultSiteID = 0 WHERE DefaultSiteID = @SiteID
Print 'Updated DefaulSiteIDs'

--Delete the Site
DELETE pSites WHERE SiteID = @SiteID
Print 'Deleted Site'




GO
GRANT EXECUTE ON  [dbo].[vpspDeleteSite] TO [VCSPortal]
GO
