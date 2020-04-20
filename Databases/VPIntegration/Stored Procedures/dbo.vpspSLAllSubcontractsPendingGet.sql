SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspSLAllSubcontractsPendingGet]
/************************************************************
* CREATED:		7/16/07		CHS
* Modified:		12/4/07		chs
*				1/14/2008	chs
*				06/30/2010 - issue #135813 expanded subcontract to 30 characters.
*
*
* USAGE:
*   gets Pending Subcontract
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job, Vendor, and VendorGroup from pUsers --%Vendor% & %VendorGroup%
*
************************************************************/
(@JCCo bCompany, @Job bJob, @SL VARCHAR(30), @KeyID int = Null)

AS
SET NOCOUNT ON;

select
p.PMCo, p.Project, p.Seq, 

p.RecordType, 
case 
	when p.ACO is null then 'Pending'
	else 'Approved'
	end as 'RecordTypeDescription',

p.PCOType,
t.Description as 'PCOTypeDescription',

p.PCO, 

p.PCOItem, 
i.Description as 'PCOItemDescription',

p.ACO, 
p.ACOItem, p.Line, p.PhaseGroup, 

p.Phase, 

p.CostType, 

p.VendorGroup, 

p.Vendor, 
p.SLCo, p.SL, p.SLItem, p.SLItemDescription, 

p.SLItemType,
case p.SLItemType
	when 1 then 'Regular'
	when 2 then 'Change Order'
	when 3 then 'Back Charge'
	when 4 then 'Add-On'
	else 'Unknown'
	end as 'SLItemTypeDescription', 

p.SLAddon,
a.Description as 'AddonDescription', 

p.SLAddonPct, 

(isnull(p.SLAddonPct, 0) * 100) as 'SLAddonPercentage',

p.Units, p.UM, p.UnitCost, p.Amount, p.SubCO, 

p.WCRetgPct, 

(isnull(p.WCRetgPct, 0) * 100) as 'WCRetgPercent', 

p.SMRetgPct, 

(isnull(p.SMRetgPct, 0) * 100) as 'SMRetgPercent',

p.Supplier, 
v.Name as 'SupplierName', 

p.InterfaceDate, p.SendFlag, p.Notes, p.SLMth, p.SLTrans, p.IntFlag, 
p.UniqueAttchID, p.KeyID

from PMSL p with (nolock)
	left join SLAD a with (nolock) on p.SLCo = a.SLCo and p.SLAddon = a.Addon
	left Join PMDT t with (nolock) on p.PCOType = t.DocType
	left Join PMOI i with (nolock) on p.PMCo = i.PMCo and p.Project = i.Project and p.PCOType = i.PCOType and p.PCO = i.PCO and p.PCOItem = i.PCOItem
	left join APVM v with (nolock) on p.VendorGroup = v.VendorGroup and p.Supplier = v.Vendor

where p.PMCo = @JCCo and p.Project = @Job and p.SL = @SL and p.InterfaceDate is null 
	and p.KeyID = IsNull(@KeyID, p.KeyID)


GO
GRANT EXECUTE ON  [dbo].[vpspSLAllSubcontractsPendingGet] TO [VCSPortal]
GO
