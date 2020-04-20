SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspAPMyPurchaseOrderItemsGet] 
/************************************************************
* CREATED:     7/19/07     CHS
* Modified:	   10/22/07    CHS
*			   07/27/2011  TRL TK-07143  Expand bPO parameters/varialbles to varchar(30)
*              8/08/12     DanW (via Tom J) Cleans up the get proc so that it handles getting a single record and handle nulls
* USAGE:
*   gets AP Purchase Order Items
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo and Job 
*
************************************************************/
(@POCo bCompany = Null, @PO varchar(30) = Null, @KeyID int = Null)

AS
	SET NOCOUNT ON;
	
select 
i.POCo, i.PO, i.POItem, i.ItemType, i.MatlGroup, i.Material, 
i.VendMatId, i.Description, i.UM, i.RecvYN, i.PostToCo, i.Loc, 
i.Job, 

i.Job as 'POItemJob',

i.PhaseGroup, i.Phase, i.JCCType, i.Equip, i.CompType, 
i.Component, i.EMGroup, i.CostCode, i.EMCType, i.WO, i.WOItem, 
i.GLCo, i.GLAcct, i.ReqDate, i.TaxGroup, i.TaxCode, i.TaxType, 
i.OrigUnits, i.OrigUnitCost, i.OrigECM, i.OrigCost, i.OrigTax, 
i.CurUnits, i.CurUnitCost, i.CurECM, i.CurCost, i.CurTax, i.RecvdUnits, 
i.RecvdCost, i.BOUnits, i.BOCost, i.TotalUnits, i.TotalCost, 
i.TotalTax, i.InvUnits, i.InvCost, i.InvTax, i.RemUnits, i.RemCost, 
i.RemTax, i.InUseMth, i.InUseBatchId, i.PostedDate, i.Notes, 
i.RequisitionNum, i.AddedMth, i.AddedBatchID, i.UniqueAttchID, 
i.PayCategory, i.PayType, i.KeyID,

case i.RecvYN
	when 'Y' then 'Yes'
	when 'N' then 'No'
	else ''
end as 'RecvYesNo',

case i.ItemType
	when 1 then 'Job'
	when 2 then 'Inventory'
	when 3 then 'Expense'
	when 4 then 'Equipment'
	when 5 then 'Work Order'
	else ''
end as 'ItemTypeDescription',

j.Description as 'POItemJobDescription',

isnull(i.CurCost,0) + isnull(i.CurTax,0) as 'RemainingTotal'

	
from POIT i with (nolock)
	left join JCJM j with (nolock) on i.POCo = j.JCCo and i.Job = j.Job

where i.POCo = IsNull(@POCo, i.POCo)
 and i.PO = IsNull(@PO, i.PO)
  and i.KeyID = IsNull(@KeyID, i.KeyID)
GO
GRANT EXECUTE ON  [dbo].[vpspAPMyPurchaseOrderItemsGet] TO [VCSPortal]
GO
