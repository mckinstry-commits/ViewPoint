SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[vfPOITWithPMMFInfo](@Company int, @PurchaseOrder varchar(30), @POItem smallint)
RETURNS TABLE
AS
/********************************************
* Created By:	GF 04/15/2010 - issue #138434
* Modified By:	GF 06/27/2011 - TK-06437
*
*
* returns PM Material Detail for PO items
* used in view POITPM.
*
********************************************/

RETURN (SELECT top 1 f.InterfaceDate, f.ACO, f.ACOItem, f.PCOType, f.PCO, f.PCOItem, f.POCONum
			FROM dbo.bPMMF f with (nolock)
			where f.POCo=@Company and f.PO=@PurchaseOrder and f.POItem=@POItem and InterfaceDate is not null
			order by f.InterfaceDate desc, f.ACO desc, f.ACOItem desc, f.PCOType desc,
			f.PCO desc, f.PCOItem DESC, f.POCONum)
GO
GRANT SELECT ON  [dbo].[vfPOITWithPMMFInfo] TO [public]
GO
