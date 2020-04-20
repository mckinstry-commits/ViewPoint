SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspMenuTemplateLinksOrphanCleanup]
(@MenuTemplateID int)

AS

SET NOCOUNT ON;

--Delete all the Menu Security for any orphaned menu items so that the Menu items
--themselves can be deleted.
DELETE FROM pMenuTemplateLinkRoles WHERE MenuTemplateID = @MenuTemplateID AND MenuTemplateLinkID IN
(SELECT MenuTemplateLinkID FROM pMenuTemplateLinks WHERE MenuTemplateID = @MenuTemplateID
AND ParentID NOT IN (SELECT MenuTemplateLinkID FROM pMenuTemplateLinks WHERE MenuTemplateID = @MenuTemplateID)
AND ParentID <> 0)

--Delete all of the Menu items for a MenuTemplateID that are not top level menu items and no longer
--have a parent
DELETE FROM pMenuTemplateLinks WHERE MenuTemplateID = @MenuTemplateID
AND ParentID NOT IN (SELECT MenuTemplateLinkID FROM pMenuTemplateLinks WHERE MenuTemplateID = @MenuTemplateID)
AND ParentID <> 0



GO
GRANT EXECUTE ON  [dbo].[vpspMenuTemplateLinksOrphanCleanup] TO [VCSPortal]
GO
