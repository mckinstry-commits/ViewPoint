SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPORSGrid    Script Date: 02/09/2000 9:36:08 AM ******/
CREATE  proc [dbo].[bspPORSGrid]
/****************************************************************************
* CREATED BY: 	DANF 02/07/2000
* MODIFIED BY:	GF 08/23/2011 TK-07879 PO ITEM LINE
*
*
* USAGE:
* 	Fills grid in PO Initialize Receipts Expenses
*
* INPUT PARAMETERS:
*
* OUTPUT PARAMETERS:

*	See Select statement below
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
*****************************************************************************/
(@POCo bCompany = null , @mth bMonth = null, @batchid bBatchID = null)
   
as
set nocount on

declare @rcode as integer

SET @rcode = 0

BEGIN

----TK-07879
SELECT PORS.BatchSeq, PORS.PO, PORS.POItem, PORS.POItemLine, POIT.Material, POIT.Description,
	CASE line.ItemType WHEN 1 THEN 'Job'
                       WHEN 2 THEN 'Inventory'
                       WHEN 3 THEN 'Expense'
                       WHEN 4 THEN 'Equipment'
                       when 5 THEN 'Work Order'
                       WHEN 6 THEN 'SM Work Order'
                       END 'Type',
		POIT.UM, PORS.RecvdUnits, PORS.RecvdCost
from dbo.bPORS PORS
LEFT OUTER JOIN dbo.vPOItemLine line ON line.POCo=PORS.Co AND line.PO=PORS.PO AND line.POItem=PORS.POItem AND line.POItemLine=PORS.POItemLine
LEFT OUTER JOIN dbo.bPOIT POIT on PORS.Co=POIT.POCo and PORS.PO=POIT.PO and PORS.POItem=POIT.POItem
LEFT OUTER JOIN dbo.bPOHD POHD on POHD.POCo = PORS.Co and POHD.PO = PORS.PO
where PORS.Co = @POCo 
	AND PORS.Mth = @mth
	AND PORS.BatchId = @batchid



bspexit:
	return @rcode
	
END

GO
GRANT EXECUTE ON  [dbo].[bspPORSGrid] TO [public]
GO
