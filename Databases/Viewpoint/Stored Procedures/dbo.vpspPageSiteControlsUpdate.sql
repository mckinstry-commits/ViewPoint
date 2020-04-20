SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPageSiteControlsUpdate]
(
	@PageSiteTemplateID int,
	@PortalControlID int,
	@ControlPosition int,
	@ControlIndex int,
	@RoleID int,
	@Original_PageSiteControlID int,
	@Original_ControlIndex int,
	@Original_ControlPosition int,
	@Original_PageSiteTemplateID int,
	@Original_PortalControlID int,
	@Original_RoleID int,
	@PageSiteControlID int,
	@HeaderText varchar(50),
	@SiteID int,
	@Original_SiteID int
)
AS

SET NOCOUNT OFF;

IF @PageSiteTemplateID = -1
	BEGIN
	SET @PageSiteTemplateID = NULL
	END

IF @Original_PageSiteTemplateID = -1
	BEGIN
	SET @Original_PageSiteTemplateID = NULL
	END

UPDATE pPageSiteControls SET PageSiteTemplateID = @PageSiteTemplateID,  
	PortalControlID = @PortalControlID, ControlPosition = @ControlPosition, 
	ControlIndex = @ControlIndex, RoleID = @RoleID, HeaderText = @HeaderText, SiteID = @SiteID 
	WHERE (PageSiteControlID = @Original_PageSiteControlID) AND (ControlIndex = @Original_ControlIndex) 
		AND (ControlPosition = @Original_ControlPosition) AND (PortalControlID = @Original_PortalControlID) AND (RoleID = @Original_RoleID);
	
SELECT PageSiteControlID, ISNULL(PageSiteTemplateID, -1) AS PageSiteTemplateID, PortalControlID, 
	ControlPosition, ControlIndex, RoleID, HeaderText, SiteID 
	FROM pPageSiteControls 
	WHERE (PageSiteControlID = @PageSiteControlID)


GO
GRANT EXECUTE ON  [dbo].[vpspPageSiteControlsUpdate] TO [VCSPortal]
GO
