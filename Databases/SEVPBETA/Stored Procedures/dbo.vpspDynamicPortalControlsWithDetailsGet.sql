SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE dbo.vpspDynamicPortalControlsWithDetailsGet
AS
	
SET NOCOUNT ON;

SELECT p.Name, p.Description, p.PortalControlID, l.TopLeftTableID, l.TopCenterTableID,
l.TopRightTableID, l.CenterLeftTableID, l.CenterCenterTableID, l.CenterRightTableID, 
l.BottomRightTableID, l.BottomCenterTableID, l.BottomRightTableID, 
ISNULL(tl.DetailsID, -1) As 'TopLeft', 
ISNULL(tc.DetailsID, -1) As 'TopCenter',
ISNULL(tr.DetailsID, -1) As 'TopRight', 
ISNULL(cl.DetailsID, -1) As 'CenterLeft', 
ISNULL(cc.DetailsID, -1) As 'CenterCenter', 
ISNULL(cr.DetailsID, -1) As 'CenterRight', 
ISNULL(bl.DetailsID, -1) As 'BottomLeft', 
ISNULL(bc.DetailsID, -1) As 'BottomCenter', 
ISNULL(br.DetailsID, -1) As 'BottomRight'
 from pPortalControlLayout l 
INNER JOIN pPortalControls p ON l.PortalControlID = p.PortalControlID
LEFT JOIN pPortalHTMLTables tl ON l.TopLeftTableID = tl.HTMLTableID
LEFT JOIN pPortalHTMLTables tc ON l.TopCenterTableID = tc.HTMLTableID
LEFT JOIN pPortalHTMLTables tr ON l.TopRightTableID = tr.HTMLTableID
LEFT JOIN pPortalHTMLTables bl ON l.BottomLeftTableID = bl.HTMLTableID
LEFT JOIN pPortalHTMLTables bc ON l.BottomCenterTableID = bc.HTMLTableID
LEFT JOIN pPortalHTMLTables br ON l.BottomRightTableID = br.HTMLTableID
LEFT JOIN pPortalHTMLTables cl ON l.CenterLeftTableID = cl.HTMLTableID
LEFT JOIN pPortalHTMLTables cc ON l.CenterCenterTableID = cc.HTMLTableID
LEFT JOIN pPortalHTMLTables cr ON l.CenterRightTableID = cr.HTMLTableID
WHERE TopLeftTableID IN (Select HTMLTableID as TopLeftTableID FROM
pPortalHTMLTables WHERE DetailsID IS NOT NULL) 




GO
GRANT EXECUTE ON  [dbo].[vpspDynamicPortalControlsWithDetailsGet] TO [VCSPortal]
GO
