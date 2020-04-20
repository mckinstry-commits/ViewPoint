SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspAPSubcontractInvoiceGet
/************************************************************
* CREATED:     2/21/06  CHS
*
* USAGE:
*   gets AP Subcontracl Invoices
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo and Job 
*
************************************************************/
(@JCCo bCompany, @Job bJob, @VendorGroup bGroup, @FirmNumber bFirm, @Contact bEmployee)

AS
SET NOCOUNT ON;


select 
h.APRef, h.InvDate, h.Description as 'InvoiceDescription',
l.APCo, l.Mth, l.APTrans, l.APLine, l.LineType, l.PO, l.POItem, 
l.ItemType, l.SL, l.SLItem, l.JCCo, l.Job, l.PhaseGroup, l.Phase, 
l.JCCType, l.EMCo, l.WO, l.WOItem, l.Equip, l.EMGroup, l.CostCode, 
l.EMCType, l.CompType, l.Component, l.INCo, l.Loc, l.MatlGroup, 
l.Material, l.GLCo, l.GLAcct, l.Description, l.UM, l.Units, l.UnitCost, 
l.ECM, l.VendorGroup, l.Supplier, l.PayType, l.GrossAmt, l.MiscAmt, 
l.MiscYN, l.TaxGroup, l.TaxCode, l.TaxType, l.TaxBasis, l.TaxAmt, 
l.Retainage, l.Discount, l.BurUnitCost, l.BECM, l.Notes, l.POPayTypeYN, 
l.UniqueAttchID, l.PayCategory 

from APTL l with (nolock)
	left join APTH h with (nolock) on l.APCo = h.APCo 
				and l.Mth = h.Mth 
				and l.VendorGroup = h.VendorGroup
				and l.APTrans = h.APTrans

where l.JCCo = @JCCo and l.Job = @Job and l.LineType = 7 and h.Vendor = @FirmNumber



GO
GRANT EXECUTE ON  [dbo].[vpspAPSubcontractInvoiceGet] TO [VCSPortal]
GO
