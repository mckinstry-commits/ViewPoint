SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPageSiteControlsInsert]
(
	@PageSiteTemplateID int,
	@PortalControlID int,
	@ControlPosition int,
	@ControlIndex int,
	@RoleID int,
	@HeaderText varchar(50),
	@SiteID int
)
AS

SET NOCOUNT OFF;

IF @PageSiteTemplateID = -1
	BEGIN
	SET @PageSiteTemplateID = NULL
	END

INSERT INTO pPageSiteControls(PageSiteTemplateID, PortalControlID, ControlPosition, 
	ControlIndex, RoleID, HeaderText, SiteID) 
VALUES (@PageSiteTemplateID, @PortalControlID, @ControlPosition, @ControlIndex, 
	@RoleID, @HeaderText, @SiteID);
	
SELECT PageSiteControlID, ISNULL(PageSiteTemplateID, -1) As PageSiteTemplateID, PortalControlID, 
	ControlPosition, ControlIndex, RoleID, HeaderText, SiteID 
	FROM pPageSiteControls WHERE (PageSiteControlID = SCOPE_IDENTITY())

GO
GRANT EXECUTE ON  [dbo].[vpspPageSiteControlsInsert] TO [VCSPortal]
GO
