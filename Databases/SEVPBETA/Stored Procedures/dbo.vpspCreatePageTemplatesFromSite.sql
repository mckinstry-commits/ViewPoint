SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Chris Gall
-- Create date: 1/11/2012
-- Description:	If a template is created from a site, any custom pages that were added to the site
--		will need PageTemplates created for them.  This proc finds all PageSiteTemplates for a site
--		and creates PageTemplates where pPageSiteTemplates PageTemplateID is null for the site.
-- =============================================
Create PROCEDURE [dbo].[vpspCreatePageTemplatesFromSite] 
	@SiteID int
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @PageSiteTemplates TABLE ( PageSiteTemplateID INT )
	DECLARE @PageSiteControls TABLE ( PageSiteControlID INT )
	
	-- GET all PageSiteTemplates with NULL PageTemplate
	INSERT INTO @PageSiteTemplates (PageSiteTemplateID)
		SELECT PageSiteTemplateID
		  FROM pPageSiteTemplates
		 WHERE SiteID = @SiteID
		   AND ( PageTemplateID IS NULL OR PageTemplateID = 444 )
		   
	DECLARE @PageSiteTemplateID INT
	DECLARE @PageSiteControlID INT

	-- LOOP through all the 	@PageSiteTemplates
	SELECT TOP (1) @PageSiteTemplateID = PageSiteTemplateID
	FROM @PageSiteTemplates

	WHILE @PageSiteTemplateID IS NOT NULL
	BEGIN	
		-- CREATE the new PageTemplate	
		INSERT INTO pPageTemplates (RoleID, AvailableToMenu, Name, Description, Notes, ClientModified)
			SELECT RoleID, AvailableToMenu, Name, Description, Notes, 1
			  FROM pPageSiteTemplates
			 WHERE PageSiteTemplateID = @PageSiteTemplateID
			 
		-- GET the new PageTemplate ID
		DECLARE @NewPageTemplateID AS INT
		select @NewPageTemplateID = SCOPE_IDENTITY()
				
		-- UPDATE the PageSite so it now has a template
		UPDATE pPageSiteTemplates SET PageTemplateID = @NewPageTemplateID WHERE PageSiteTemplateID = @PageSiteTemplateID
				
		-- GET all the PageSiteControls to add to the PageTemplate
		INSERT INTO @PageSiteControls (PageSiteControlID)
			SELECT PageSiteControlID
			  FROM pPageSiteControls
			 WHERE PageSiteTemplateID = @PageSiteTemplateID
	
		-- LOOP through all the PageSiteControls
		SELECT TOP (1) @PageSiteControlID = PageSiteControlID
		FROM @PageSiteControls
		
		WHILE @PageSiteControlID IS NOT NULL
		BEGIN
			-- CREATE the new PageTemplate controls from the PageSiteControls
			INSERT INTO pPageTemplateControls (PageTemplateID, PortalControlID, ControlPosition, ControlIndex, RoleID, HeaderText)
				SELECT @NewPageTemplateID, PortalControlID, ControlPosition, ControlIndex, RoleID, HeaderText
				  FROM pPageSiteControls
				 WHERE PageSiteControlID = @PageSiteControlID
				 
			-- GET the new PageTemplateControl ID
			DECLARE @NewPageTemplateControlID AS INT
			SELECT @NewPageTemplateControlID = SCOPE_IDENTITY()		
			
			-- UPDATE new PageTemplateControlSecurity records.  NOTE a trigger on pPageTemplateControls inserts the records
			UPDATE pPageTemplateControlSecurity
			   SET AllowAdd = ps.AllowAdd
				 , AllowEdit = ps.AllowEdit
				 , AllowDelete = ps.AllowDelete
			  FROM pPageTemplateControlSecurity
		INNER JOIN pPageSiteControlSecurity ps
				ON ps.RoleID = pPageTemplateControlSecurity.RoleID
			   AND PageSiteControlID = @PageSiteControlID 
			 WHERE pPageTemplateControlSecurity.PageTemplateControlID = @NewPageTemplateControlID
			   AND pPageTemplateControlSecurity.RoleID = ps.RoleID
			   					
			-- REMOVE the PageSiteControlID from @PageSiteControls to continue loop
			DELETE FROM @PageSiteControls WHERE PageSiteControlID = @PageSiteControlID
			SET @PageSiteControlID = NULL

			-- GET the next PageSiteControlID from @PageSiteControls to continue loop
			SELECT TOP (1) @PageSiteControlID = PageSiteControlID
			FROM @PageSiteControls
		END
			
		-- REMOVE the PageSiteTemplates from @PageSiteTemplates to continue loop	
		DELETE FROM @PageSiteTemplates WHERE PageSiteTemplateID = @PageSiteTemplateID
		SET @PageSiteTemplateID = NULL

		-- GET the next PageSiteTemplateID from @PageSiteTemplateID to continue loop
		SELECT TOP (1) @PageSiteTemplateID = PageSiteTemplateID
		FROM @PageSiteTemplates
	END
END

GO
GRANT EXECUTE ON  [dbo].[vpspCreatePageTemplatesFromSite] TO [VCSPortal]
GO
