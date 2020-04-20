SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspSLSubcontractInvoiceItemsGet]
/************************************************************
* CREATED:     3/20/07  CHS
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
(@APCo bCompany, @Mth bMonth, @APTrans bTrans, @SL VARCHAR(30),
	@KeyID int = Null)

AS
SET NOCOUNT ON;

select 
i.APCo, i.Mth, i.APTrans, i.APLine, i.LineType, i.PO, i.POItem, 
i.ItemType, i.SL, i.SLItem, i.JCCo, i.Job, i.PhaseGroup, i.Phase, 
i.JCCType, i.EMCo, i.WO, i.WOItem, i.Equip, i.EMGroup, i.CostCode, 
i.EMCType, i.CompType, i.Component, i.INCo, i.Loc, i.MatlGroup, 
i.Material, i.GLCo, i.GLAcct, i.Description, i.UM, i.Units, 
i.UnitCost, i.ECM, i.VendorGroup, i.Supplier, i.PayType, 
i.GrossAmt, i.MiscAmt, i.MiscYN, i.TaxGroup, i.TaxCode, 
i.TaxType, i.TaxBasis, i.TaxAmt, i.Retainage, i.Discount, 
i.BurUnitCost, i.BECM, i.Notes, i.POPayTypeYN, i.UniqueAttchID, 
i.PayCategory, 

i.Notes as 'SubInvItemsNotes',
i.KeyID

from APTL i with (nolock)

where i.APCo = @APCo and i.Mth = @Mth and i.APTrans = @APTrans and i.SL = @SL
and i.KeyID = IsNull(@KeyID, i.KeyID)
GO
GRANT EXECUTE ON  [dbo].[vpspSLSubcontractInvoiceItemsGet] TO [VCSPortal]
GO
