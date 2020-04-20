SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[ptvPOHD]
AS

-- PO Headers
-- Only selecting PO's that have a description and whose status is 0 (Open)

SELECT POHD.PO, isnull(POHD.Description,'No Description') as "Description", POHD.Vendor, APVM.Name AS "Vendor Name", 
	POHD.Status, POHD.POCo, POHD.VendorGroup												-- why include Status if must be 0?

FROM POHD with (nolock)
	INNER JOIN APVM with (nolock) ON (POHD.VendorGroup = APVM.VendorGroup) and (POHD.Vendor = APVM.Vendor)

WHERE POHD.Status=0

GO
GRANT SELECT ON  [dbo].[ptvPOHD] TO [public]
GRANT INSERT ON  [dbo].[ptvPOHD] TO [public]
GRANT DELETE ON  [dbo].[ptvPOHD] TO [public]
GRANT UPDATE ON  [dbo].[ptvPOHD] TO [public]
GO
