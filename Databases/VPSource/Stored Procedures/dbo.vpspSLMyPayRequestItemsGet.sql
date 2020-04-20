SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspSLMyPayRequestItemsGet]
/************************************************************
* CREATED:		4/10/07		CHS
* MODIFIED:		5/31/07		chs
* MODIFIED:		11/26/07	CHS
*				06/29/2010 - issue #135813 expanded subcontract to 30 characters
*
* USAGE:
*   gets pay request items
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    SLCo, SL
*
************************************************************/
(@SLCo bCompany, @SL VARCHAR(30),
	@KeyID int = Null)

AS
SET NOCOUNT ON;

select  
i.SLCo, i.UserName, i.SL, i.SLItem, i.ItemType,
i.Description, i.PhaseGroup, i.Phase, i.UM, i.CurUnits,
i.CurUnitCost, 

--i.CurCost, 

i.PrevWCUnits, i.PrevWCCost,
i.WCUnits, i.WCCost, i.WCRetPct, i.WCRetAmt, i.PrevSM,
i.Purchased, i.Installed, i.SMRetPct, i.SMRetAmt,
i.LineDesc, i.VendorGroup, i.Supplier, i.BillMonth,
i.BillNumber, i.BillChangedYN, i.WCPctComplete,
isnull(i.WCPctComplete,0) * 100 as '100xWCPctComplete',
i.WCToDate,
 
((isnull(i.PrevWCCost, 0) + 
		isnull(i.PrevSM, 0)) + ((isnull(i.WCCost, 0) + isnull(i.Purchased, 0)) - 
										isnull(i.Installed, 0))) as 'ToDate', 

i.WCToDateUnits, i.Notes,

isnull(i.CurCost, 0) as 'CurrentCost',

(isnull(i.PrevWCCost, 0) + isnull(i.PrevSM, 0)) as 'PrevInvoiced',
((isnull(i.WCCost, 0) + isnull(i.Purchased, 0)) - isnull(i.Installed, 0)) as 'Total',
i.KeyID

from SLWI i with (nolock)

where i.SLCo = @SLCo and i.SL = @SL
and i.KeyID = IsNull(@KeyID, i.KeyID)
GO
GRANT EXECUTE ON  [dbo].[vpspSLMyPayRequestItemsGet] TO [VCSPortal]
GO
