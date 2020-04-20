SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE       PROCEDURE dbo.vpspPageSiteControlsDelete
(
	@Original_PageSiteControlID int,
	@Original_ControlIndex int,
	@Original_ControlPosition int,
	@Original_PageSiteTemplateID int,
	@Original_PortalControlID int,
	@Original_RoleID int
	)
AS
	SET NOCOUNT OFF;

IF @Original_PageSiteTemplateID = -1
	BEGIN
	SET @Original_PageSiteTemplateID = NULL
	END


DELETE FROM pPageSiteControlSecurity WHERE PageSiteControlID = @Original_PageSiteControlID

DELETE FROM pPageSiteControls WHERE (PageSiteControlID = @Original_PageSiteControlID) 
AND (ControlIndex = @Original_ControlIndex) 
AND (ControlPosition = @Original_ControlPosition) 
AND (PageSiteTemplateID = @Original_PageSiteTemplateID OR (@Original_PageSiteTemplateID IS NULL AND PageSiteTemplateID IS NULL))
AND (PortalControlID = @Original_PortalControlID) 
AND (RoleID = @Original_RoleID) 




GO
GRANT EXECUTE ON  [dbo].[vpspPageSiteControlsDelete] TO [VCSPortal]
GO
