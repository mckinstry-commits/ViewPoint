SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE dbo.vpspSLAllSubcontractsGet
/************************************************************
* CREATED:     7/16/07  CHS
*
* USAGE:
*   gets Subcontract Headers
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job
*
************************************************************/
(@JCCo bCompany, @Job bJob, @KeyID int = Null)

AS
SET NOCOUNT ON;

Select
h.SLCo, h.SL, h.JCCo, h.Job, h.Description, h.VendorGroup, 

h.Vendor, 
f.Name as 'VendorName',

h.HoldCode, 
c.Description as 'HoldCodeDescripton',

h.PayTerms, 
t.Description as 'PayTermsDescription',

h.CompGroup, 
g.Description as 'CompGroupDescription',

h.Status, 
case h.Status
	when 0 then 'Open'
	when 1 then 'Completed'
	when 2 then 'Closed'
	when 3 then 'Pending'
	else 'Unknown'
	end as 'StatusDescription',

h.MthClosed, h.InUseMth, h.InUseBatchId, 
h.Purge, 

h.Approved, 
case h.Approved
	when 'Y' then 'Yes'
	when 'N' then 'No'
	else h.Approved
	end as 'ApprovedYesNo',

h.ApprovedBy, h.Notes, h.AddedMth, h.AddedBatchID, 
h.OrigDate, h.UniqueAttchID, h.KeyID

from SLHD h with (nolock)
	left join APVM f with (nolock) on h.Vendor = f.Vendor and f.VendorGroup = h.VendorGroup
	left join HQHC c with (nolock) on h.HoldCode = c.HoldCode
	left join HQPT t with (nolock) on h.PayTerms = t.PayTerms
	left join HQCG g with (nolock) on h.CompGroup = g.CompGroup

where h.JCCo = @JCCo and h.Job = @Job 
	and h.KeyID = IsNull(@KeyID, h.KeyID)


GO
GRANT EXECUTE ON  [dbo].[vpspSLAllSubcontractsGet] TO [VCSPortal]
GO
