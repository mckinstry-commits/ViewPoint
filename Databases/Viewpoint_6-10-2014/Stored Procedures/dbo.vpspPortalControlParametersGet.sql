SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPortalControlParametersGet]
(@PortalControlID int)

AS
SET NOCOUNT ON;

SELECT DetailsFieldID, ColumnName FROM pPortalDetailsField f
INNER JOIN pPortalDetails d ON f.DetailsID = d.DetailsID
INNER JOIN pPortalHTMLTables h ON d.DetailsID = h.DetailsID
INNER JOIN pPortalControlLayout l ON h.HTMLTableID = l.TopLeftTableID
WHERE l.PortalControlID = @PortalControlID

UNION

SELECT DetailsFieldID,  ColumnName FROM pPortalDetailsField f
INNER JOIN pPortalDetails d ON f.DetailsID = d.DetailsID
INNER JOIN pPortalHTMLTables h ON d.DetailsID = h.DetailsID
INNER JOIN pPortalControlLayout l ON h.HTMLTableID = l.TopCenterTableID
WHERE l.PortalControlID = @PortalControlID

UNION 

SELECT DetailsFieldID,  ColumnName FROM pPortalDetailsField f
INNER JOIN pPortalDetails d ON f.DetailsID = d.DetailsID
INNER JOIN pPortalHTMLTables h ON d.DetailsID = h.DetailsID
INNER JOIN pPortalControlLayout l ON h.HTMLTableID = l.TopRightTableID
WHERE l.PortalControlID = @PortalControlID

UNION

SELECT DetailsFieldID,  ColumnName FROM pPortalDetailsField f
INNER JOIN pPortalDetails d ON f.DetailsID = d.DetailsID
INNER JOIN pPortalHTMLTables h ON d.DetailsID = h.DetailsID
INNER JOIN pPortalControlLayout l ON h.HTMLTableID = l.CenterLeftTableID
WHERE l.PortalControlID = @PortalControlID

UNION

SELECT DetailsFieldID,  ColumnName FROM pPortalDetailsField f
INNER JOIN pPortalDetails d ON f.DetailsID = d.DetailsID
INNER JOIN pPortalHTMLTables h ON d.DetailsID = h.DetailsID
INNER JOIN pPortalControlLayout l ON h.HTMLTableID = l.CenterCenterTableID
WHERE l.PortalControlID = @PortalControlID

UNION

SELECT DetailsFieldID,  ColumnName FROM pPortalDetailsField f
INNER JOIN pPortalDetails d ON f.DetailsID = d.DetailsID
INNER JOIN pPortalHTMLTables h ON d.DetailsID = h.DetailsID
INNER JOIN pPortalControlLayout l ON h.HTMLTableID = l.CenterRightTableID
WHERE l.PortalControlID = @PortalControlID

UNION

SELECT DetailsFieldID,  ColumnName FROM pPortalDetailsField f
INNER JOIN pPortalDetails d ON f.DetailsID = d.DetailsID
INNER JOIN pPortalHTMLTables h ON d.DetailsID = h.DetailsID
INNER JOIN pPortalControlLayout l ON h.HTMLTableID = l.BottomLeftTableID
WHERE l.PortalControlID = @PortalControlID

UNION

SELECT DetailsFieldID,  ColumnName FROM pPortalDetailsField f
INNER JOIN pPortalDetails d ON f.DetailsID = d.DetailsID
INNER JOIN pPortalHTMLTables h ON d.DetailsID = h.DetailsID
INNER JOIN pPortalControlLayout l ON h.HTMLTableID = l.BottomCenterTableID
WHERE l.PortalControlID = @PortalControlID

UNION

SELECT DetailsFieldID,  ColumnName FROM pPortalDetailsField f
INNER JOIN pPortalDetails d ON f.DetailsID = d.DetailsID
INNER JOIN pPortalHTMLTables h ON d.DetailsID = h.DetailsID
INNER JOIN pPortalControlLayout l ON h.HTMLTableID = l.BottomRightTableID
WHERE l.PortalControlID = @PortalControlID
GO
GRANT EXECUTE ON  [dbo].[vpspPortalControlParametersGet] TO [VCSPortal]
GO
