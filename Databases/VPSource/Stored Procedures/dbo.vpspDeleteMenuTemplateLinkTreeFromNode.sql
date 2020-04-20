SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Tom Jochums
-- Create date: 2011-09-30
-- Description:	Deletes a MenuTemplateLink and all its related data from the
--              database. Currently the MenuTemplateLinkRoles are on a cascade
--              delete. PageTemplates must be manually deleted though
--              due to them being potentially referenced by multiple
--              MenuSiteLinks
-- =============================================
CREATE PROCEDURE [dbo].[vpspDeleteMenuTemplateLinkTreeFromNode]
	-- Add the parameters for the stored procedure here
	@MenuTemplateID int,
	@MenuTemplateLinkID int
AS
BEGIN
	CREATE Table #LinksToDelete	(MenuTemplateLinkID int, ParentID int, MenuTemplateID int, [Level] int);
	-- Use recursion to gather all the ancestor links that need to be deleted 
	-- for this Operation.

	WITH LinksToDelete (MenuTemplateLinkID , ParentID , MenuTemplateID , [Level])
	AS
	( 		SELECT p.MenuTemplateLinkID AS MenuTemplateLinkID
				 , p.ParentID AS ParentID
				 , p.MenuTemplateID
				 , 0 AS [Level]
			  FROM pMenuTemplateLinks AS p 
			 WHERE MenuTemplateID = @MenuTemplateID
			   AND MenuTemplateLinkID = @MenuTemplateLinkID
		UNION ALL
			SELECT p.MenuTemplateLinkID AS MenuTemplateLinkID
				 , p.ParentID AS ParentID
				 , p.MenuTemplateID
				 , d.[Level] + 1
			  FROM LinksToDelete AS d 
		INNER JOIN pMenuTemplateLinks AS p 
				ON p.ParentID = d.MenuTemplateLinkID 
			   AND p.MenuTemplateID = d.MenuTemplateID 
	)
	INSERT INTO #LinksToDelete SELECT MenuTemplateLinkID , ParentID , MenuTemplateID , [Level] FROM LinksToDelete
	
	-- DELETE THE ROLES
		DELETE mslr
		  FROM pMenuTemplateLinkRoles mslr 
	INNER JOIN #LinksToDelete del 
			ON del.MenuTemplateLinkID = mslr.MenuTemplateLinkID
		   AND del.MenuTemplateID = mslr.MenuTemplateID 
	
	-- DELETE THE MENU LINKS
		DELETE msl 
		  FROM pMenuTemplateLinks msl 
	INNER JOIN #LinksToDelete del 
			ON del.MenuTemplateLinkID = msl.MenuTemplateLinkID
		   AND del.MenuTemplateID = msl.MenuTemplateID 

	DROP Table #LinksToDelete;	
END

GO
GRANT EXECUTE ON  [dbo].[vpspDeleteMenuTemplateLinkTreeFromNode] TO [VCSPortal]
GO
