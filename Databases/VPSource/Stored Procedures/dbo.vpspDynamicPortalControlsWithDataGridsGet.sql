SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE        PROCEDURE dbo.vpspDynamicPortalControlsWithDataGridsGet
AS
	
SET NOCOUNT ON;

SELECT p.Name, p.Description, p.PortalControlID, l.TopLeftTableID, h.DataGridID from pPortalControlLayout l 
INNER JOIN pPortalControls p ON l.PortalControlID = p.PortalControlID
INNER JOIN pPortalHTMLTables h ON l.TopLeftTableID = h.HTMLTableID
WHERE TopLeftTableID IN (Select HTMLTableID as TopLeftTableID FROM
pPortalHTMLTables WHERE DataGridID IS NOT NULL) 





GO
GRANT EXECUTE ON  [dbo].[vpspDynamicPortalControlsWithDataGridsGet] TO [VCSPortal]
GO
