SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE       PROCEDURE [dbo].[vpspPageTemplateControlsInsert]
(
	@PageTemplateID int,
	@PortalControlID int,
	@ControlPosition int,
	@ControlIndex int,
	@RoleID int,
	@HeaderText varchar(50)
)
AS

SET NOCOUNT OFF;

INSERT INTO pPageTemplateControls(PageTemplateID, PortalControlID, 
	ControlPosition, ControlIndex, RoleID, HeaderText) VALUES (@PageTemplateID, @PortalControlID, 
	@ControlPosition, @ControlIndex, @RoleID, @HeaderText);
	

SELECT PageTemplateControlID, PageTemplateID, t.PortalControlID, ControlPosition, 
	ControlIndex, RoleID, HeaderText 
	FROM pPageTemplateControls t
	LEFT JOIN pPortalControls p ON t.PortalControlID = p.PortalControlID
WHERE (PageTemplateControlID = SCOPE_IDENTITY())

GO
GRANT EXECUTE ON  [dbo].[vpspPageTemplateControlsInsert] TO [VCSPortal]
GO
