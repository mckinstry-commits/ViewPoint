SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspAPMyInvoiceLinesGet]
/************************************************************
* CREATED:     7/26/07  CHS
*              8/08/12  DanW (via Tom J) Cleans up the get proc so that it handles getting a single record and handle nulls
* USAGE:
*   gets AP Invoice Lines
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    APCo and APTrans 
*
************************************************************/
(@APCo bCompany = Null, @Mth bMonth = Null, @APTrans bTrans = Null, @KeyID int = Null)

AS
	SET NOCOUNT ON;
	
Select
i.APCo, i.Mth, i.APTrans, i.APLine, i.LineType, i.PO, i.POItem, i.ItemType, 
i.SL, i.SLItem, i.JCCo, i.Job, i.PhaseGroup, i.Phase, i.JCCType, i.EMCo, 
i.WO, i.WOItem, i.Equip, i.EMGroup, i.CostCode, i.EMCType, i.CompType, 
i.Component, i.INCo, i.Loc, i.MatlGroup, i.Material, i.GLCo, i.GLAcct, 
i.Description, i.UM, i.Units, i.UnitCost, i.ECM, i.VendorGroup, i.Supplier, 
i.PayType, i.GrossAmt, i.MiscAmt, i.MiscYN, i.TaxGroup, i.TaxCode, i.TaxType, 
i.TaxBasis, i.TaxAmt, i.Retainage, i.Discount, i.BurUnitCost, i.BECM, 
i.Notes, i.POPayTypeYN, i.UniqueAttchID, i.PayCategory, i.KeyID,

case i.LineType
	when 1 then 'Job'
	when 2 then 'Inventory'
	when 3 then 'Expense'
	when 4 then 'Equipment'
	when 5 then 'Work Order'
	when 6 then 'Purchase Order'
	when 7 then 'Subcontract'
	else '' 
end as 'LineTypeDescription'

from APTL i with (nolock)

where i.APCo = IsNull(@APCo, i.APCo)
 and i.Mth = IsNull(@Mth, i.Mth)
  and i.APTrans = IsNull(@APTrans, i.APTrans)
  and i.KeyID = IsNull(@KeyID, i.KeyID)
GO
GRANT EXECUTE ON  [dbo].[vpspAPMyInvoiceLinesGet] TO [VCSPortal]
GO
