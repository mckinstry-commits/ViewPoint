SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/************************************************************************
* CREATED:	    
* MODIFIED:	AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables-  
*
* Purpose:

* returns 1 and error msg if failed
*
*************************************************************************/
CREATE PROCEDURE [dbo].[vpspPageSiteControlsCopyPageTemplate]
(
	@PageTemplateID int,
	@SiteID int,
	@RoleID int
)	
AS
SET NOCOUNT OFF;
-- #142350 - renaming @roleid 
DECLARE @pagesitetemplateid int,
		@requiredpagetemplateid int,
		@portalcontrolid int,
		@controlposition int,
		@controlindex int,
		@RoleIDCur int,
		@headertext varchar(50),
		@pagesitecontrolid int,
		@pagetemplatecontrolid int,
		@returnvalue int

--Insert the PageTemplate detail information into the PageSiteTemplate table
INSERT INTO pPageSiteTemplates (SiteID, PageTemplateID, RoleID, AvailableToMenu, Name, Description, Notes)
	(SELECT @SiteID, @PageTemplateID, @RoleID, AvailableToMenu, Name, Description, Notes FROM pPageTemplates 
	WHERE PageTemplateID = @PageTemplateID);

--Get the PageSiteTemplateID of the newly copied Page
SELECT @pagesitetemplateid = PageSiteTemplateID FROM pPageSiteTemplates WHERE (PageSiteTemplateID = SCOPE_IDENTITY())
SET @returnvalue = @pagesitetemplateid

-- DEBUG
--PRINT 'NEW PAGE INSERTED: ' + cast(@pagesitetemplateid as varchar(255))
--SELECT @pagesitetemplateid AS 'PageSiteTemplateID'


--PRINT 'BEGIN PAGESITECONTROLS CURSOR'

--Insert all of the PageTemplateControls associated with the copied PageTemplate into the PageSiteControls table
DECLARE pcPageSiteControls CURSOR local fast_forward FOR
	SELECT PageTemplateControlID, PortalControlID, ControlPosition, ControlIndex, RoleID, HeaderText 
		FROM pPageTemplateControls WHERE PageTemplateID = @PageTemplateID

	OPEN pcPageSiteControls
	FETCH next FROM pcPageSiteControls INTO @pagetemplatecontrolid, @portalcontrolid, @controlposition, @controlindex, @RoleIDCur,
		@headertext

		WHILE (@@FETCH_STATUS = 0)
			BEGIN
				--Insert the associated PageTemplateControls into the PageSiteControls table
				INSERT INTO pPageSiteControls (PageSiteTemplateID, SiteID, PortalControlID, ControlPosition, 
					ControlIndex, RoleID, HeaderText)
				VALUES (@pagesitetemplateid, @SiteID, @portalcontrolid, @controlposition, @controlindex, @RoleIDCur,
					@headertext); 
				
				SELECT @pagesitecontrolid = PageSiteControlID FROM pPageSiteControls WHERE (PageSiteControlID = SCOPE_IDENTITY())
				
				-- DEBUG
				--PRINT 'NEW PAGESITECONTROL INSERTED: '  + cast(@pagesitecontrolid as varchar(255))
				--SELECT @pagesitecontrolid AS 'PageSiteControlID'
				
				--Create the PageSiteControl Role Security records for the just inserted PageSiteControlID
				INSERT INTO pPageSiteControlSecurity (PageSiteControlID, RoleID, SiteID, AllowAdd, AllowEdit, AllowDelete)
					(SELECT DISTINCT @pagesitecontrolid, RoleID, @SiteID, AllowAdd, AllowEdit, AllowDelete FROM pPageTemplateControlSecurity
					WHERE PageTemplateID = @PageTemplateID AND PageTemplateControlID = @pagetemplatecontrolid) 

				-- DEBUG
				--SELECT * FROM pPageSiteControlSecurity WHERE PageSiteControlID = @pagesitecontrolid and SiteID = @SiteID
				--PRINT 'SECURITY RECORDS INSERTED FOR: ' + cast(@pagesitecontrolid as varchar(255))
				
				FETCH next FROM pcPageSiteControls INTO @pagetemplatecontrolid, @portalcontrolid, @controlposition, @controlindex, @RoleIDCur,
					@headertext
			END

CLOSE pcPageSiteControls
DEALLOCATE pcPageSiteControls
--PRINT 'END PAGESITECONTROLS CURSOR'

--PRINT 'BEGIN REQUIREDPAGES CURSOR'
--Use a cursor to add any pages to the Site that are associated (required) by the copied PageTemplate
DECLARE pcRequiredPages CURSOR local fast_forward FOR
	SELECT PageTemplateID FROM pPageTemplates WHERE PageTemplateID IN 
	(SELECT PageTemplateID FROM pPageTemplates WHERE PatriarchID = @PageTemplateID)
	
	OPEN pcRequiredPages
	FETCH next FROM pcRequiredPages INTO @requiredpagetemplateid
	
	WHILE (@@FETCH_STATUS = 0)
		BEGIN
		
		--Insert the PageTemplate detail information into the PageSiteTemplate table
		INSERT INTO pPageSiteTemplates (SiteID, PageTemplateID, RoleID, AvailableToMenu, Name, Description, Notes)
			(SELECT @SiteID, @requiredpagetemplateid, @RoleID, AvailableToMenu, Name, Description, Notes FROM pPageTemplates 
			WHERE PageTemplateID = @requiredpagetemplateid);
		
		SELECT @pagesitetemplateid = PageSiteTemplateID FROM pPageSiteTemplates WHERE (PageSiteTemplateID = SCOPE_IDENTITY())
		
		-- DEBUG
		--PRINT 'REQUIRED PAGE INSERTED: ' + cast(@pagesitetemplateid as varchar(255))
		--SELECT @pagesitetemplateid AS 'PageSiteTemplateID'
		
		-- DEBUG
		--PRINT 'BEGIN REQUIREDPAGES PAGESITECONTROLS CURSOR'
		DECLARE pcPageSiteControls CURSOR local fast_forward FOR
			SELECT PortalControlID, ControlPosition, ControlIndex, RoleID, HeaderText, PageTemplateControlID
	 			FROM pPageTemplateControls WHERE PageTemplateID = @requiredpagetemplateid
	
			OPEN pcPageSiteControls
			FETCH next FROM pcPageSiteControls INTO @portalcontrolid, @controlposition, @controlindex, @RoleIDCur,
				@headertext, @pagetemplatecontrolid
		
			WHILE (@@FETCH_STATUS = 0)
				BEGIN
					
					-- DEBUG
					--PRINT 'INSERTING NEW PAGESITECONTROLS for PAGESITETEMPLATE: ' + cast(@pagesitetemplateid as varchar(255))

					--Insert the associated PageTemplateControls into the PageSiteControls table
					INSERT INTO pPageSiteControls (PageSiteTemplateID, SiteID, PortalControlID, ControlPosition, 
						ControlIndex, RoleID, HeaderText)
					VALUES (@pagesitetemplateid, @SiteID, @portalcontrolid, @controlposition, @controlindex, @RoleIDCur,
						@headertext); 
				
					SELECT @pagesitecontrolid = PageSiteControlID FROM pPageSiteControls WHERE (PageSiteControlID = SCOPE_IDENTITY())
					
					-- DEBUG
					--PRINT 'NEW PAGESITECONTROL INSERTED: ' + cast(@pagesitecontrolid as varchar(255))
					--SELECT @pagesitecontrolid AS 'PageSiteControlID'
					--PRINT 'PREPARING TO INSERT SECURITY RECORDS FOR: ' + cast(@pagesitecontrolid as varchar(255))
					--select * from pPageSiteControlSecurity where PageSiteControlID = @pagesitecontrolid and SiteID = @SiteID

					IF NOT EXISTS (SELECT * FROM pPageSiteControlSecurity WHERE PageSiteControlID = @pagesitecontrolid and SiteID = @SiteID)
						BEGIN
						--Create the PageSiteControl Role Security records for the just inserted PageSiteControlID
						INSERT INTO pPageSiteControlSecurity (PageSiteControlID, RoleID, SiteID, AllowAdd, AllowEdit, AllowDelete)
							(SELECT DISTINCT @pagesitecontrolid AS 'PageSiteControlID', RoleID, @SiteID AS 'SiteID', AllowAdd, AllowEdit, AllowDelete FROM pPageTemplateControlSecurity
							WHERE PageTemplateID = @requiredpagetemplateid AND PageTemplateControlID = @pagetemplatecontrolid) 

						-- DEBUG
						--SELECT DISTINCT @pagesitecontrolid AS 'PageSiteControlID', RoleID, @SiteID as 'SiteID', AllowAdd, AllowEdit, AllowDelete FROM pPageTemplateControlSecurity
						--	WHERE PageTemplateID = @requiredpagetemplateid  AND PageTemplateControlID = @pagetemplatecontrolid
						--PRINT 'REQUIRED SECURITY RECORDS INSERTED FOR PAGESITECONTROL: ' + cast(@pagesitecontrolid as varchar(255))
					END

			FETCH next FROM pcPageSiteControls INTO @portalcontrolid, @controlposition, @controlindex, @RoleIDCur,
				@headertext, @pagetemplatecontrolid
			END
					
	 	CLOSE pcPageSiteControls
		DEALLOCATE pcPageSiteControls
		--PRINT 'END REQUIREDPAGES PAGESITECONTROLS CURSOR'

	FETCH next FROM pcRequiredPages INTO @requiredpagetemplateid
    END
	
CLOSE pcRequiredPages
DEALLOCATE pcRequiredPages
--PRINT 'END PAGESITECONTROLS CURSOR'

--Give full permission to Viewpoint, Portal Admin and the Site Admin
UPDATE pPageSiteControlSecurity SET AllowAdd = 1, AllowEdit = 1, AllowDelete = 1 WHERE RoleID = 0 OR RoleID = 1

--PRINT 'SECURITY RECORDS UPDATED'
/*
		--Insert the associated PageTemplateControls into the PageSiteControls table
		INSERT INTO pPageSiteControls (PageSiteTemplateID, SiteID, PortalControlID, ControlPosition, 
			ControlIndex, RoleID, HeaderText)
		(SELECT @pagesitetemplateid, @SiteID, PortalControlID, ControlPosition, ControlIndex, RoleID,
			HeaderText 
		 	FROM pPageTemplateControls WHERE PageTemplateID = @requiredpagetemplateid)
*/
RETURN @returnvalue

GO
GRANT EXECUTE ON  [dbo].[vpspPageSiteControlsCopyPageTemplate] TO [VCSPortal]
GO
