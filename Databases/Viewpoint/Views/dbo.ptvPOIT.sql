SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[ptvPOIT]
AS

-- PO Items
-- Selecting only those that are flagged for receiving, Open PO's, and 
-- Whose backorder qty is > 0
-- Should resrtict in PT on PO and PO company

SELECT POIT.POItem, POIT.Material, POIT.Description, POIT.UM, POIT.BOUnits, 
	POIT.POCo, POIT.PO

FROM POIT with (nolock)
	INNER JOIN POHD with (nolock) ON (POIT.POCo=POHD.POCo) and (POIT.PO=POHD.PO)

WHERE POIT.RecvYN='Y' AND POHD.Status=0

GO
GRANT SELECT ON  [dbo].[ptvPOIT] TO [public]
GRANT INSERT ON  [dbo].[ptvPOIT] TO [public]
GRANT DELETE ON  [dbo].[ptvPOIT] TO [public]
GRANT UPDATE ON  [dbo].[ptvPOIT] TO [public]
GO
