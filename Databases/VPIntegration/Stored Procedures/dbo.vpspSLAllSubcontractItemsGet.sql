SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspSLAllSubcontractItemsGet]
/************************************************************
* CREATED:     7/16/07  CHS
*				06/20/2010 - ISSUE #135813 expanded subcontract to 30 characters
*
*
* USAGE:
*   gets Subcontract Items
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job, SL
************************************************************/
(@JCCo bCompany, @Job bJob, @SL VARCHAR(30),
	@KeyID int = Null)

AS
SET NOCOUNT ON;

select 
i.SLCo, i.SL, i.SLItem, 

i.ItemType, 
case i.ItemType
	when 1 then 'Regular'
	when 2 then 'Change Order'
	when 3 then 'Back Charge'
	when 4 then 'Add-On'
	else 'Unknown'
	end as 'ItemTypeDescription',

i.Addon, 
a.Description as 'AddonDescription',

i.AddonPct, i.JCCo, i.Job, i.PhaseGroup, 

i.Phase, 
p.Description as 'PhaseDescription',

i.JCCType, 
t.Description as 'CostTypeDescription',

i.Description, i.UM, i.GLCo, i.GLAcct, i.WCRetPct, i.SMRetPct, 
i.VendorGroup, 

i.Supplier, 
v.Name as 'SupplierName', 

i.OrigUnits, i.OrigUnitCost, i.OrigCost, i.CurUnits, 
i.CurUnitCost, i.CurCost, i.StoredMatls, i.InvUnits, i.InvCost, i.InUseMth, 
i.InUseBatchId, i.Notes, i.AddedMth, i.AddedBatchID, i.UniqueAttchID, i.KeyID

from SLIT i with (nolock)
	left join SLAD a with (nolock) on i.SLCo = a.SLCo and i.Addon = a.Addon
	left join JCJP p with (nolock) on i.JCCo = p.JCCo and i.Job = p.Job and i.PhaseGroup = p.PhaseGroup and i.Phase = p.Phase
	left join JCCT t with (nolock) on i.PhaseGroup = t.PhaseGroup and i.JCCType = t.CostType
	left join APVM v with (nolock) on i.VendorGroup = v.VendorGroup and i.Supplier = v.Vendor

where  i.JCCo = @JCCo and i.Job = @Job and i.SL = @SL
	and i.KeyID = IsNull(@KeyID, i.KeyID)

GO
GRANT EXECUTE ON  [dbo].[vpspSLAllSubcontractItemsGet] TO [VCSPortal]
GO
