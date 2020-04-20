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
CREATE  PROCEDURE [dbo].[vpspPageSiteControlSecurityApplyToAll]
(
	@PageSiteControlID int,
	@SiteID int
)	
AS
SET NOCOUNT OFF;
-- #142350 - renaming @pagesitecontrolID 
DECLARE @portalcontrolID int,
		@PageSiteControlIDCur int
--Get the PortalControlID for the PageSiteControlID that was passed into the procedure
SELECT @portalcontrolID = PortalControlID FROM pPageSiteControls WHERE PageSiteControlID = @PageSiteControlID
--Cycle through all of the PageSiteControls that are of that particular control type (PortalControlID)
declare pcPageSiteControls cursor local fast_forward for
	SELECT PageSiteControlID FROM pPageSiteControls 
	WHERE PortalControlID = @portalcontrolID AND PageSiteControlID <> @PageSiteControlID AND SiteID = @SiteID
		
	open pcPageSiteControls
	fetch next from pcPageSiteControls into @PageSiteControlIDCur
		
	while (@@FETCH_STATUS = 0)
		begin
			--Remove any existing records to prevent duplicate record conflicts			
			DELETE FROM pPageSiteControlSecurity WHERE PageSiteControlID = @PageSiteControlIDCur
			--Create the PageSiteControl Role Security records for this PageSiteControlID
			INSERT INTO pPageSiteControlSecurity (PageSiteControlID, RoleID, SiteID, AllowAdd, AllowEdit, AllowDelete)
				(SELECT @PageSiteControlIDCur, RoleID, @SiteID, AllowAdd, AllowEdit, AllowDelete FROM pPageSiteControlSecurity
				WHERE PageSiteControlID = @PageSiteControlID) 
		
			PRINT 'SECURITY RECORDS INSERTED'
			fetch next from pcPageSiteControls into  @PageSiteControlIDCur
		end
			
close pcPageSiteControls
deallocate pcPageSiteControls
--Give full permission to Viewpoint, Portal Admin
UPDATE pPageSiteControlSecurity SET AllowAdd = 1, AllowEdit = 1, AllowDelete = 1 
WHERE RoleID = 0 OR RoleID = 1
PRINT 'SECURITY RECORDS UPDATED'


GO
GRANT EXECUTE ON  [dbo].[vpspPageSiteControlSecurityApplyToAll] TO [VCSPortal]
GO
