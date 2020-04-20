SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPMMyPOItemGet] 
/************************************************************
* CREATED:		10/24/07	CHS
* Modified:		11/07/07	CHS
* Modified:		07/15/08	CHS
*		TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
*
* USAGE:
*   Returns PM Purchase Orders
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    PostToCo, PO
************************************************************/
(@PostToCo bCompany, @Job bJob, @PO varchar(30), @KeyID int = Null)

AS
SET NOCOUNT ON;

select
i.POCo, i.PO, i.POItem, i.ItemType, i.MatlGroup, i.Material, i.VendMatId, 
i.Description, i.UM, i.RecvYN, i.PostToCo, i.Loc, i.Job, i.PhaseGroup, 
i.Phase, i.JCCType, i.Equip, i.CompType, i.Component, i.EMGroup, i.CostCode, 
i.EMCType, i.WO, i.WOItem, i.GLCo, i.GLAcct, i.ReqDate, i.TaxGroup, 
i.TaxCode, i.TaxType, i.OrigUnits, i.OrigUnitCost, i.OrigECM, i.OrigCost, 
i.OrigTax, i.CurUnits, i.CurUnitCost, i.CurECM, i.CurCost, i.CurTax, 
i.RecvdUnits, i.RecvdCost, i.BOUnits, i.BOCost, i.TotalUnits, i.TotalCost, 
i.TotalTax, i.InvUnits, i.InvCost, i.InvTax, i.RemUnits, i.RemCost, 
i.RemTax, i.InUseMth, i.InUseBatchId, i.PostedDate, i.Notes, 
i.RequisitionNum, i.AddedMth, i.AddedBatchID, i.UniqueAttchID, 
i.PayCategory, i.PayType, i.KeyID, m.Description as 'MaterialDescription'

From POIT i with (nolock)
	left join HQMT m with (nolock) on i.MatlGroup = m.MatlGroup and i.Material = m.Material

Where i.PostToCo=@PostToCo and i.Job = @Job and i.PO=@PO and i.KeyID = IsNull(@KeyID, i.KeyID)



GO
GRANT EXECUTE ON  [dbo].[vpspPMMyPOItemGet] TO [VCSPortal]
GO
