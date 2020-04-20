SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  StoredProcedure [dbo].[vpspPageSiteControlsGet]    Script Date: 04/12/2011 18:55:44 ******/
CREATE PROCEDURE [dbo].[vpspPageSiteControlsGet]
AS

/************************************************************
* CREATED:	GWC 3/18/2005
* MODIFIED: INNO.Dylan 4/12/2011
*
* USAGE:	Returns all Page Site Controls
*
* CALLED: 	ViewpointCS Portal  
*
* INPUTS: 	None   
************************************************************/

SET NOCOUNT ON;

SELECT PageSiteControlID, ISNULL(PageSiteTemplateID, -1) As PageSiteTemplateID, 
s.PortalControlID, ControlIndex, RoleID, 
ISNULL(s.HeaderText, p.Name) As HeaderText, SiteID,
ControlPosition FROM pPageSiteControls s 
LEFT JOIN pPortalControls p ON s.PortalControlID = p.PortalControlID
ORDER BY PageSiteTemplateID, ControlIndex

GO
GRANT EXECUTE ON  [dbo].[vpspPageSiteControlsGet] TO [VCSPortal]
GO
