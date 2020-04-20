SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Tom Jochums
-- Create date: 2011-10-03
-- Modified By: Chris G 10/31/2011- D-03296 - Fix but stopping pMenuSiteLinkRoles from copying
--
-- Description:	This was a heavy refactor of the original stored proc that
--				was used to copy templates to sites. Wipes out the old 
--				controls on a site, and then replaces it with all new controls
--              and menus - with all security coming from the template.
-- =============================================
CREATE PROCEDURE [dbo].[vspMenuSiteLinksCopyTemplate]
(
  	@SiteID int,
  	@MenuTemplateID int
)
AS
BEGIN
	--Delete the current menu, pages and controls for the site
	exec vpspDeleteSiteMenuAndControls @SiteID;

	-- Recursively get all PageTemplates that need copying  
  	WITH PageTemplatesToCopy (PageTemplateID, [Level])
	AS
	( 		SELECT mtl.PageTemplateID
				 , 0 AS [Level]
			  FROM pMenuTemplateLinks AS mtl 
			 WHERE mtl.MenuTemplateID = @MenuTemplateID
		UNION ALL
			SELECT pt.PageTemplateID
				 , pts.[Level] + 1
			  FROM PageTemplatesToCopy AS pts 
		INNER JOIN pPageTemplates AS pt
				ON pts.PageTemplateID = pt.PatriarchID 
	)
   
	-- Copy all pages that don't already exist on the site.
	INSERT INTO pPageSiteTemplates 
		(SiteID, PageTemplateID, RoleID, AvailableToMenu, Name, Description, Notes)
		(SELECT @SiteID, pt.PageTemplateID, pt.RoleID, pt.AvailableToMenu, pt.Name, pt.Description, pt.Notes 
           FROM pPageTemplates pt
           JOIN PageTemplatesToCopy pmtl
             ON pt.PageTemplateID = pmtl.PageTemplateID 
      LEFT JOIN pPageSiteTemplates pst
             ON pst.PageTemplateID = pt.PageTemplateID AND pst.SiteID = @SiteID
          WHERE pmtl.PageTemplateID IS NOT NULL AND pst.PageTemplateID IS NULL  		
		)
  		
	--Copy all the Controls associated with the Templates
	INSERT INTO pPageSiteControls 
		(PageSiteTemplateID, SiteID, PortalControlID, ControlPosition, ControlIndex, RoleID, HeaderText)
  		(SELECT s.PageSiteTemplateID, @SiteID, p.PortalControlID, p.ControlPosition, p.ControlIndex, p.RoleID, p.HeaderText 
  	       FROM pPageTemplateControls p 
     INNER JOIN pPageSiteTemplates s 
             ON p.PageTemplateID = s.PageTemplateID 
          WHERE s.SiteID = @SiteID
        )
 
	--Insert all the Security Records associated with the Controls of the Templates
	INSERT INTO pPageSiteControlSecurity (PageSiteControlID, RoleID, SiteID, AllowAdd, AllowEdit, AllowDelete)
		  (SELECT psc.PageSiteControlID, ptcs.RoleID, pst.SiteID, ptcs.AllowAdd, ptcs.AllowEdit, ptcs.AllowDelete  
		     FROM pPageSiteControls psc
	         JOIN pPageSiteTemplates pst 
	           ON psc.PageSiteTemplateID = pst.PageSiteTemplateID
	          AND pst.SiteID = @SiteID
             JOIN pPageTemplateControls ptc
               ON ptc.PageTemplateID = pst.PageTemplateID 
              AND ptc.PortalControlID = psc.PortalControlID 
              AND ptc.ControlPosition = psc.ControlPosition
              AND ptc.ControlIndex = psc.ControlIndex                    		
	         JOIN pPageTemplateControlSecurity ptcs
	           ON ptcs.PageTemplateControlID = ptc.PageTemplateControlID
        LEFT JOIN pPageSiteControlSecurity pscs
               ON psc.PageSiteControlID = pscs.PageSiteControlID
            WHERE pscs.PageSiteControlID IS NULL
		   )
 
	--Copy the Template from MenuLinks and insert the Menu Structure as the new Menu for the Site
	INSERT INTO pMenuSiteLinks (MenuSiteLinkID, SiteID, MenuTemplateID, RoleID, Caption, PageSiteTemplateID, ParentID, MenuLevel, MenuOrder)
	(
			SELECT m.MenuTemplateLinkID As MenuSiteLinkID, @SiteID, m.MenuTemplateID, m.RoleID, m.Caption
			     , p.PageSiteTemplateID, m.ParentID, m.MenuLevel, m.MenuOrder 
			  FROM pMenuTemplateLinks m 
	     LEFT JOIN pPageSiteTemplates p 
	            ON m.PageTemplateID = p.PageTemplateID 
	         WHERE m.MenuTemplateID = @MenuTemplateID 
	           AND p.SiteID = @SiteID
	 UNION 
			SELECT m.MenuTemplateLinkID As MenuSiteLinkID, @SiteID, m.MenuTemplateID, m.RoleID, m.Caption
				 , m.PageTemplateID, m.ParentID, m.MenuLevel, m.MenuOrder 
              FROM pMenuTemplateLinks m 
             WHERE m.MenuTemplateID = @MenuTemplateID 
               AND m.PageTemplateID IS NULL)
 
	--Create the Role Security records for the Menu Template to the Site
	INSERT INTO pMenuSiteLinkRoles (MenuSiteLinkID, SiteID, RoleID, AllowAccess)
	(
			SELECT pmtlr.MenuTemplateLinkID As MenuSiteLinkID, @SiteID, pmtlr.RoleID, pmtlr.AllowAccess 
			  FROM pMenuTemplateLinkRoles pmtlr
		 LEFT JOIN pMenuSiteLinkRoles pmslr
		        ON pmtlr.MenuTemplateLinkID = pmslr.MenuSiteLinkID
		       AND pmslr.RoleID = pmtlr.RoleID
		       AND pmslr.SiteID = @SiteID
         LEFT JOIN pMenuSiteLinks
                ON pmtlr.MenuTemplateLinkID = pMenuSiteLinks.MenuSiteLinkID
               AND pMenuSiteLinks.SiteID = @SiteID
  	         WHERE pmtlr.MenuTemplateID = @MenuTemplateID
  	           AND pmslr.MenuSiteLinkID IS NULL
  	) 
  
	Declare @DefaultPageSiteTemplateID AS INTEGER
  
	-- Set the default page.  Use the Welcome (home) page if it exists 
	-- otherwise use the first menu link.  It can be changed later.  
    IF EXISTS(SELECT TOP 1 1 FROM pPageSiteTemplates WHERE SiteID = @SiteID AND PageTemplateID = 444)
		BEGIN
			--Make the default page the welcome page
			--PageTemplateID 444 = WelcomePage Template
			SELECT @DefaultPageSiteTemplateID = PageSiteTemplateID
			  FROM pPageSiteTemplates
			 WHERE SiteID = @SiteID AND PageTemplateID = 444
		END
	ELSE
		BEGIN
			-- Get the link hierarchy
			WITH SelectableMenuLinks (MenuSiteLinkID, PageSiteTemplateID, SiteID, [Level], Caption, MenuOrder, ParentMenuOrder)
			AS
			( 		SELECT mtl.MenuSiteLinkID
						 , mtl.PageSiteTemplateID
						 , mtl.SiteID
						 , 0 AS [Level]
						 , mtl.Caption
						 , mtl.MenuOrder
						 , 0
					  FROM pMenuSiteLinks AS mtl 	
					  WHERE SiteID = @SiteID and ParentID = 0 	   
				UNION ALL
					SELECT pmtl.MenuSiteLinkID				 
						 , pmtl.PageSiteTemplateID
						 , pmtl.SiteID				 
						 , sml.[Level] + 1
						 , pmtl.Caption
						 , pmtl.MenuOrder
						 , sml.MenuOrder
					  FROM SelectableMenuLinks AS sml 
				INNER JOIN pMenuSiteLinks AS pmtl
						ON sml.MenuSiteLinkID = pmtl.ParentID
					   AND sml.SiteID = pmtl.SiteID
			)					
			
			  -- Select the first link that would appear in the menu that has a 
			  -- PageSiteTemplateID set.
			  SELECT TOP 1 @DefaultPageSiteTemplateID = PageSiteTemplateID 
			    FROM SelectableMenuLinks
			   WHERE PageSiteTemplateID IS NOT NULL
		    ORDER BY [Level], ParentMenuOrder, MenuOrder			
		END
	
	UPDATE pSites
	   SET PageSiteTemplateID = @DefaultPageSiteTemplateID
	 WHERE SiteID = @SiteID
END

GO
GRANT EXECUTE ON  [dbo].[vspMenuSiteLinksCopyTemplate] TO [public]
GO
