SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/************************************************************************
* CREATED:	Chris G (D-05282) 6/21/12   
* MODIFIED:	
*
* Purpose:
*	Synchronize control security between parent and child controls.  When
*	a grid control has a detail control behind it (and vise-versa), the 
*	security needs to match.  This proc will syncronize all role security 
*	at once.
*
* Input: PageSiteControlID to sync.  This can be the parent or the child.
*
*************************************************************************/
CREATE PROCEDURE [dbo].[vpspSyncPageSiteControlSecurity] (@PageSiteControlID int)	
AS
SET NOCOUNT OFF;
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @IsDetail bit, @PortalControlID int, @SiteID int

	SELECT @PortalControlID = PortalControlID, @SiteID = SiteID FROM pPageSiteControls
	WHERE PageSiteControlID = @PageSiteControlID

	DECLARE @RelatedSiteControls AS TABLE
	(
		PageSiteControlID int,
		PortalControlID int
	)

	-- Determine if this control is a detail control or grid
	EXEC vpspIsDetailControl @PortalControlID, @IsDetail OUTPUT
    
	IF @IsDetail = 0 
		-- If control is a Parent Grid, get the child details controls
		BEGIN
			DECLARE @gridPageTemplateID int
			
			-- Get the page template the control edit/view navigates to
			SELECT DISTINCT @gridPageTemplateID = NavigationPageID FROM pPortalControlButtons
			WHERE PortalControlID = @PortalControlID AND (ButtonID = 8 OR ButtonID = 36)
		
			-- Get all the child page site controls that only on the immediate child page
			INSERT INTO @RelatedSiteControls (PageSiteControlID, PortalControlID)
				SELECT pPageSiteControls.PageSiteControlID, pPageSiteControls.PortalControlID FROM pPageSiteControls
				INNER JOIN pPageSiteTemplates ON pPageSiteTemplates.PageSiteTemplateID = pPageSiteControls.PageSiteTemplateID
					AND PageTemplateID = @gridPageTemplateID AND pPageSiteTemplates.SiteID = @SiteID

		END
	ELSE IF @IsDetail = 1
		-- If control is a detail control, get the parent grid control
		BEGIN
			DECLARE @pageTemplateID int, @parentPortalControlID int

			-- Get the detail controls page template
			SELECT @pageTemplateID = PageTemplateID FROM pPageSiteTemplates
			INNER JOIN pPageSiteControls ON pPageSiteControls.PageSiteTemplateID = pPageSiteTemplates.PageSiteTemplateID
				AND PageSiteControlID = @PageSiteControlID
				
			-- Find which control navigates to the details page template when the view or
			-- edit button is clicked.
			SELECT DISTINCT @parentPortalControlID = PortalControlID FROM pPortalControlButtons WHERE NavigationPageID = @pageTemplateID
			AND (ButtonID = 8 OR ButtonID = 36)				
		
			-- Get all the parent page site control
			INSERT INTO @RelatedSiteControls (PageSiteControlID, PortalControlID)
				SELECT pPageSiteControls.PageSiteControlID, pPageSiteControls.PortalControlID FROM pPageSiteControls
				INNER JOIN pPageSiteTemplates ON pPageSiteTemplates.PageSiteTemplateID = pPageSiteControls.PageSiteTemplateID
					AND pPageSiteTemplates.SiteID = @SiteID
				WHERE PortalControlID = @parentPortalControlID
		END
	
	-- Store @PageSiteControlID so we can iterate through the records for each related control
	DECLARE @ControlSecurity AS TABLE
	(
		RoleID int,
		AllowAdd bit,
		AllowEdit bit,
		AllowDelete bit
	)
		
	INSERT INTO @ControlSecurity (RoleID, AllowAdd, AllowEdit, AllowDelete)
    SELECT RoleID, AllowAdd, AllowEdit, AllowDelete FROM pPageSiteControlSecurity WHERE PageSiteControlID = @PageSiteControlID
	
	-- LOOP through the related controls.	
	DECLARE @nextPageSiteControlID int, @nextPortalControlID int, @nextIsDetail bit
	DECLARE @nextRoleID int, @nextAllowAdd bit, @nextAllowEdit bit, @nextAllowDelete bit
	
	SELECT TOP(1) @nextPageSiteControlID = PageSiteControlID, @nextPortalControlID = PortalControlID 
	FROM @RelatedSiteControls
	WHILE @nextPageSiteControlID IS NOT NULL
	BEGIN						
		EXEC vpspIsDetailControl @nextPortalControlID, @nextIsDetail OUTPUT
		-- Update only the controls that are the opposite of the parent (Grid -> Detail or
		-- Detail -> Grid).  The logic above should put the correct controls in the table
		IF @nextIsDetail != @IsDetail
		BEGIN
			SELECT TOP(1) @nextRoleID = RoleID, @nextAllowAdd = AllowAdd, @nextAllowEdit = AllowEdit, @nextAllowDelete = AllowDelete
			FROM @ControlSecurity

			WHILE @nextRoleID IS NOT NULL
			BEGIN
				-- Update related control security (this proc handles insert or update)
				EXEC vpspSetPageSiteControlSecurity @nextPageSiteControlID, @nextRoleID, @nextAllowAdd, @nextAllowEdit, @nextAllowDelete
				
				-- Delete ROLE record from temp table and reselect to continue loop
				DELETE FROM @ControlSecurity WHERE RoleID = @nextRoleID
				SET @nextRoleID = NULL
				
				SELECT TOP(1) @nextRoleID = RoleID, @nextAllowAdd = AllowAdd, @nextAllowEdit = AllowEdit, @nextAllowDelete = AllowDelete
				FROM @ControlSecurity
			END	
		END
	
	
		-- Delete CONTROL record from temp table and reselect to continue loop
		DELETE FROM @RelatedSiteControls WHERE PageSiteControlID = @nextPageSiteControlID
		SET @nextPageSiteControlID = NULL

		SELECT TOP(1) @nextPageSiteControlID = PageSiteControlID, @nextPortalControlID = PortalControlID 
		FROM @RelatedSiteControls			
	END
END
GO
GRANT EXECUTE ON  [dbo].[vpspSyncPageSiteControlSecurity] TO [VCSPortal]
GO
