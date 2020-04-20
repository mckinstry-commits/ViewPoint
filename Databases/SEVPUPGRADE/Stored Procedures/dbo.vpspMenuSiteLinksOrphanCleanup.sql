SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspMenuSiteLinksOrphanCleanup]
(@SiteID int)

AS

SET NOCOUNT ON;

--Delete all the Menu Security for any orphaned menu items so that the Menu items
--themselves can be deleted.
DELETE FROM pMenuSiteLinkRoles WHERE SiteID = @SiteID AND MenuSiteLinkID IN
(SELECT MenuSiteLinkID FROM pMenuSiteLinks WHERE SiteID = @SiteID
AND ParentID NOT IN (SELECT MenuSiteLinkID FROM pMenuSiteLinks WHERE SiteID = @SiteID)
AND ParentID <> 0)

--Delete all of the Menu items for a Site that are not top level menu items and no longer
--have a parent
DELETE FROM pMenuSiteLinks WHERE SiteID = @SiteID
AND ParentID NOT IN (SELECT MenuSiteLinkID FROM pMenuSiteLinks WHERE SiteID = @SiteID)
AND ParentID <> 0
GO
GRANT EXECUTE ON  [dbo].[vpspMenuSiteLinksOrphanCleanup] TO [VCSPortal]
GO
