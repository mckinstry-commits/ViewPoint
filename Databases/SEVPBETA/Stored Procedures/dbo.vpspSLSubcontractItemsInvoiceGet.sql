SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspSLSubcontractItemsInvoiceGet]
/************************************************************
* CREATED:     3/13/07  CHS
*				GF 06/25/2010 - issue #135813 expanded SL to varchar(30)
*
*
* USAGE:
*   gets Subcontract Invoices
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    SLCo and SL
*
************************************************************/
(@SL VARCHAR(30), @SLItem bItem,
	@KeyID int = Null)

AS
SET NOCOUNT ON;

select 
i.APCo, i.Mth, i.APTrans, i.APLine, i.LineType, i.PO, i.POItem,
i.ItemType, i.SL, i.SLItem, i.JCCo, i.Job, i.PhaseGroup, i.Phase,
i.JCCType, i.EMCo, i.WO, i.WOItem, i.Equip, i.EMGroup, i.CostCode,
i.EMCType, i.CompType, i.Component, i.INCo, i.Loc, i.MatlGroup, 
i.Material, i.GLCo, i.GLAcct, i.Description, i.UM, i.Units, i.UnitCost,
i.ECM, i.VendorGroup, i.Supplier, i.PayType, i.GrossAmt, i.MiscAmt,
i.MiscYN, i.TaxGroup, i.TaxCode, i.TaxType, i.TaxBasis, i.TaxAmt,
i.Retainage, i.Discount, i.BurUnitCost, i.BECM, i.Notes, i.POPayTypeYN,
i.UniqueAttchID, i.PayCategory, h.APRef, h.InvDate,

i.Notes as 'SubItemsInvNotes',
i.KeyID

from APTL i with (nolock)
	left join APTH h with (nolock) on i.APCo = h.APCo and i.Mth = h.Mth and i.APTrans = h.APTrans

where i.SL = @SL and i.SLItem = @SLItem
and i.KeyID = IsNull(@KeyID, i.KeyID)
GO
GRANT EXECUTE ON  [dbo].[vpspSLSubcontractItemsInvoiceGet] TO [VCSPortal]
GO
