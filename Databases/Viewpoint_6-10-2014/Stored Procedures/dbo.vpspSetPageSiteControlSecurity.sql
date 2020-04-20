SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Chris Gall
-- Create date: 11/03/2011
-- Modified: Chris G 6/21/12 TK-15632 | D-05282 - Move security sync code to vpspSyncPageSiteControlSecurity to allow for more reusability
-- Description:	Sets pPageSiteControlSecurity for the given role
-- =============================================
CREATE PROCEDURE [dbo].[vpspSetPageSiteControlSecurity]
	@PageSiteControlID int,
	@RoleID int,
	@AllowAdd bit,
	@AllowEdit bit,
	@AllowDelete bit
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @SiteID int
	
	SELECT @SiteID = SiteID FROM pPageSiteControls WHERE PageSiteControlID = @PageSiteControlID

	if exists (SELECT 1 FROM pPageSiteControlSecurity WHERE PageSiteControlID = @PageSiteControlID AND RoleID = @RoleID AND SiteID = @SiteID)
	begin
		-- If the record exists, update it
		UPDATE pPageSiteControlSecurity SET AllowAdd = @AllowAdd, AllowEdit = @AllowEdit, AllowDelete = @AllowDelete
		WHERE PageSiteControlID = @PageSiteControlID 
		AND RoleID = @RoleID
		AND SiteID = @SiteID
	end	
	else
	begin
		-- IF the record doesn't exist insert it
		INSERT INTO pPageSiteControlSecurity (PageSiteControlID, RoleID, SiteID, AllowAdd, AllowEdit, AllowDelete)
			VALUES (@PageSiteControlID, @RoleID, @SiteID, @AllowAdd, @AllowEdit, @AllowDelete)
	end

END
GO
GRANT EXECUTE ON  [dbo].[vpspSetPageSiteControlSecurity] TO [VCSPortal]
GO
