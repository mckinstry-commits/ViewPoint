SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE    PROCEDURE dbo.vpspPageTemplateControlsDelete
(
	@Original_PageTemplateControlID int,
	@Original_ControlIndex int,
	@Original_ControlPosition int,
	@Original_PageTemplateID int,
	@Original_PortalControlID int,
	@Original_RoleID int
)
AS

SET NOCOUNT OFF;

DELETE FROM pPageTemplateControls WHERE 
	(PageTemplateControlID = @Original_PageTemplateControlID) AND 
	(ControlIndex = @Original_ControlIndex) AND 
	(ControlPosition = @Original_ControlPosition) AND 
	(PageTemplateID = @Original_PageTemplateID) AND 
	(PortalControlID = @Original_PortalControlID) AND 
	(RoleID = @Original_RoleID)



GO
GRANT EXECUTE ON  [dbo].[vpspPageTemplateControlsDelete] TO [VCSPortal]
GO
