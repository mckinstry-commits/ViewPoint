SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPageTemplateControlsGet]
AS
	
SET NOCOUNT ON;

SELECT PageTemplateControlID, PageTemplateID, t.PortalControlID, ControlPosition, 
	ControlIndex, RoleID, 
HeaderText 
	FROM pPageTemplateControls t
	LEFT JOIN pPortalControls p ON t.PortalControlID = p.PortalControlID

GO
GRANT EXECUTE ON  [dbo].[vpspPageTemplateControlsGet] TO [VCSPortal]
GO
