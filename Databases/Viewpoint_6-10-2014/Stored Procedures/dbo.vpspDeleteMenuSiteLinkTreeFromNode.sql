SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Tom Jochums
-- Create date: 2011-08-18
-- Description:	Deletes a MenuSiteLink and all its related data from the
--              database. Currently the MenuSiteLinkRoles are on a cascade
--              delete. PageSiteTemplates must be manually deleted though
--              due to them being potentially referenced by multiple
--              MenuSiteLinks
-- =============================================
CREATE PROCEDURE [dbo].[vpspDeleteMenuSiteLinkTreeFromNode]
	-- Add the parameters for the stored procedure here
	@LinqPrimaryKey int
AS
BEGIN
	-- Use recursion to gather all the ancestor links that need to be deleted 
	-- for this Operation.
	DECLARE @LinksToDelete Table 
	(
		MenuSiteLinkID int, 
		ParentID int, 
		SiteID int, 
		PageSiteTemplateID int, 
		[Level] int
	)
	
	INSERT INTO @LinksToDelete (MenuSiteLinkID , ParentID , SiteID , PageSiteTemplateID , [Level])
	( 		SELECT p.MenuSiteLinkID AS MenuSiteLinkID
				 , p.ParentID AS ParentID
				 , p.SiteID AS SiteID
				 , p.PageSiteTemplateID
				 , 0 AS [Level]
			  FROM pMenuSiteLinks AS p 
			 WHERE LinqPrimaryKey = @LinqPrimaryKey
		UNION ALL
			SELECT p.MenuSiteLinkID AS MenuSiteLinkID
				 , p.ParentID AS ParentID
				 , p.SiteID AS SiteID
				 , p.PageSiteTemplateID
				 , [Level] + 1
			  FROM pMenuSiteLinks AS p 
		INNER JOIN @LinksToDelete AS d 
				ON p.ParentID = d.MenuSiteLinkID 
	)
	
	-- Delete all the pMenuSiteLinks that are ancestors of the link to be
	-- Deleted  
		DELETE msl 
		  FROM pMenuSiteLinks msl 
	INNER JOIN @LinksToDelete del 
			ON del.MenuSiteLinkID = msl.MenuSiteLinkID
		   AND del.SiteID = msl.SiteID

	-- Delete all orphaned PageSiteTemplates: The And clause here will make sure that
	-- it will only delete ones that are no longer linked to MenuSiteLinks
        DELETE pst 
          FROM pPageSiteTemplates pst
	INNER JOIN @LinksToDelete del 
	        ON pst.PageSiteTemplateID = del.PageSiteTemplateID 
	       AND 1 > (SELECT COUNT(*) FROM pMenuSiteLinks WHERE pMenuSiteLinks.PageSiteTemplateID = pst.PageSiteTemplateID)
END
GO
GRANT EXECUTE ON  [dbo].[vpspDeleteMenuSiteLinkTreeFromNode] TO [VCSPortal]
GO
