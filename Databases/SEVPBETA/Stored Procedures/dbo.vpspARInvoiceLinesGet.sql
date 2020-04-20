SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspARInvoiceLinesGet]
/************************************************************
* CREATED:		5/15/07		CHS
* MODIFIED:		12/20/07	CHS
*
* USAGE:
*   Returns the AR Invoice Line Items
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    Mth, ARTrans 
*
************************************************************/
(@Mth bMonth, @ARTrans bTrans,
	@KeyID int = Null)
AS
	SET NOCOUNT ON;
	
Select 
i.ARCo, i.Mth, i.ARTrans, i.ARLine, i.RecType, i.LineType, i.Description, 
i.GLCo, i.GLAcct, i.TaxGroup, i.TaxCode, i.Amount, i.TaxBasis, i.TaxAmount, 
i.RetgPct, i.Retainage, i.DiscOffered, i.TaxDisc, i.DiscTaken, i.ApplyMth, 
i.ApplyTrans, i.ApplyLine, i.JCCo, i.Contract, i.Item, 

j.Description as 'ItemDescription',

i.ContractUnits, 
i.Job, i.PhaseGroup, i.Phase, i.CostType, i.UM, i.JobUnits, i.JobHours, 
i.ActDate, i.INCo, i.Loc, i.MatlGroup, i.Material, i.UnitPrice, i.ECM, 
i.MatlUnits, i.CustJob, i.CustPO, i.EMCo, i.Equipment, i.EMGroup, i.CostCode, 
i.EMCType, i.Notes, i.CompType, i.Component, i.PurgeFlag, i.FinanceChg, 
i.rptApplyMth, i.rptApplyTrans, i.KeyID

from ARTL i with (nolock)
	left join JCCI j with (nolock) on i.Contract = j.Contract and i.JCCo = j.JCCo and i.Item = j.Item

where i.Mth = @Mth and i.ARTrans = @ARTrans
and i.KeyID = IsNull(@KeyID, i.KeyID)

GO
GRANT EXECUTE ON  [dbo].[vpspARInvoiceLinesGet] TO [VCSPortal]
GO
