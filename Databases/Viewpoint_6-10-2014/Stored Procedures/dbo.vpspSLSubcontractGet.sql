SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspSLSubcontractGet]
/************************************************************
* CREATED:     2/22/06  CHS
*
* USAGE:
*   gets Subcontract Headers
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job, Vendor, and VendorGroup from pUsers --%Vendor% & %VendorGroup%
*
************************************************************/
(@JCCo bCompany, @Job bJob, @Vendor bVendor, @VendorGroup bGroup,
	@KeyID int = Null)

AS
SET NOCOUNT ON;


select distinct
h.KeyID,
h.SLCo, 
h.SL, 
h.JCCo, 
h.Job, 
h.Description, 
h.VendorGroup, 
h.Vendor, 
h.HoldCode, 
h.PayTerms, 
h.CompGroup, 
h.Status, 
h.MthClosed, 
h.InUseMth, 
h.InUseBatchId, 
h.Purge, 
h.Approved, 
h.ApprovedBy, 
convert(varchar(2048), h.Notes) as 'Notes', 

convert(varchar(2048), h.Notes) as 'SubNotes', 

h.AddedMth, 
h.AddedBatchID, 
h.OrigDate, 
h.UniqueAttchID,
sum(i.OrigCost) as 'OrigCost',
sum(i.CurCost) as 'CurCost',
sum(i.InvCost) as 'InvCost'


from SLHD h with (nolock)
	left join SLIT i with (nolock) on h.SLCo = i.SLCo and h.SL = i.SL

where h.JCCo = @JCCo and h.Job = @Job and h.Vendor = @Vendor 
and h.VendorGroup = @VendorGroup
and h.KeyID = IsNull(@KeyID, h.KeyID)

group by h.KeyID, h.SLCo, h.SL, h.JCCo, h.Job, h.Description, h.VendorGroup, h.Vendor, h.HoldCode,
h.PayTerms, h.CompGroup, h.Status, h.MthClosed, h.InUseMth, h.InUseBatchId, h.Purge, h.Approved, 
h.ApprovedBy, h.AddedMth, h.AddedBatchID, h.OrigDate, h.UniqueAttchID, convert(varchar(2048), h.Notes)
GO
GRANT EXECUTE ON  [dbo].[vpspSLSubcontractGet] TO [VCSPortal]
GO
