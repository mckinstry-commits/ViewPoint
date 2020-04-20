SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE     PROCEDURE [dbo].[vpspPageTemplateControlsUpdate]
(
	@PageTemplateID int,
	@PortalControlID int,
	@ControlPosition int,
	@ControlIndex int,
	@RoleID int,
	@HeaderText varchar(50),
	@Original_PageTemplateControlID int,
	@Original_ControlIndex int,
	@Original_ControlPosition int,
	@Original_PageTemplateID int,
	@Original_PortalControlID int,
	@Original_RoleID int,
	@Original_HeaderText varchar(50),
	@PageTemplateControlID int
)
AS

SET NOCOUNT OFF;


UPDATE pPageTemplateControls SET PageTemplateID = @PageTemplateID, 
	PortalControlID = @PortalControlID, ControlPosition = @ControlPosition, 
	ControlIndex = @ControlIndex, RoleID = @RoleID, HeaderText = @HeaderText
	WHERE (PageTemplateControlID = @Original_PageTemplateControlID) 
	AND (ControlIndex = @Original_ControlIndex) AND 
	(ControlPosition = @Original_ControlPosition) AND 
	(PageTemplateID = @Original_PageTemplateID) AND 
	(PortalControlID = @Original_PortalControlID) AND 
	(RoleID = @Original_RoleID);
	
SELECT PageTemplateControlID, PageTemplateID, PortalControlID, 
	ControlPosition, ControlIndex, RoleID, HeaderText 
	FROM pPageTemplateControls WHERE (PageTemplateControlID = @PageTemplateControlID)

GO
GRANT EXECUTE ON  [dbo].[vpspPageTemplateControlsUpdate] TO [VCSPortal]
GO
