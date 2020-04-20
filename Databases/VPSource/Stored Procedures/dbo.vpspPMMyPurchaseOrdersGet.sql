SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPMMyPurchaseOrdersGet]
/************************************************************
* CREATED:     10/24/07  CHS
*
* USAGE:
*   Returns PM Purchase Orders
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job
************************************************************/
(@JCCo bCompany, @Job bJob, @KeyID int = Null)

AS
SET NOCOUNT ON;

Select distinct
p.POCo, p.PO, p.VendorGroup, p.Vendor, p.Description, p.OrderDate, 
p.OrderedBy, p.ExpDate, p.Status, p.JCCo, p.Job, p.INCo, p.Loc, 
p.ShipLoc, p.Address, p.City, p.State, p.Zip, p.ShipIns, p.HoldCode, 
p.PayTerms, p.CompGroup, p.MthClosed, p.InUseMth, p.InUseBatchId, 
p.Approved, p.ApprovedBy, p.Purge, 
cast(p.Notes as varchar(2000)) as 'Notes',
p.AddedMth, p.AddedBatchID, 
p.UniqueAttchID, p.Attention, p.PayAddressSeq, p.POAddressSeq, 
p.Address2, p.KeyID, sum(i.TotalCost) as 'TotalCost', sum(i.InvCost) as'InvCost', sum(i.RemCost) as 'RemCost',
f.FirmName as 'VendorName'

FROM POHD p with (nolock)
	left join POIT i with (nolock) on p.POCo = i.POCo and p.PO = i.PO
	left join PMFM f with (nolock) on f.VendorGroup = p.VendorGroup and f.FirmNumber = p.Vendor

Where i.PostToCo=@JCCo and i.Job=@Job and p.KeyID = IsNull(@KeyID, p.KeyID)

group by
p.POCo, p.PO, p.VendorGroup, p.Vendor, p.Description, p.OrderDate, 
p.OrderedBy, p.ExpDate, p.Status, p.JCCo, p.Job, p.INCo, p.Loc, 
p.ShipLoc, p.Address, p.City, p.State, p.Zip, p.ShipIns, p.HoldCode, 
p.PayTerms, p.CompGroup, p.MthClosed, p.InUseMth, p.InUseBatchId, 
p.Approved, p.ApprovedBy, p.Purge, 
cast(p.Notes as varchar(2000)), 
p.AddedMth, p.AddedBatchID, 
p.UniqueAttchID, p.Attention, p.PayAddressSeq, p.POAddressSeq, 
p.Address2, p.KeyID, f.FirmName



GO
GRANT EXECUTE ON  [dbo].[vpspPMMyPurchaseOrdersGet] TO [VCSPortal]
GO
