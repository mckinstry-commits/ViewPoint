SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspAPMyPurchaseOrdersGet]
/************************************************************
* CREATED:	07/19/07 CHS
* Modified:	10/22/07 CHS
* Modified:	11/27/07 CHS
*		03/26/08 TJL - Issue #127347, International Address	
*               08/08/12 DanW (via Tom J) Cleans up the get proc so that it handles getting a single record and handle nulls
* USAGE:
*   gets AP Purchase Orders
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo and Job 
*
************************************************************/
(@VendorGroup bGroup = Null, @Vendor bVendor = Null, @KeyID int = Null)

AS
	SET NOCOUNT ON;

select
p.POCo, 

c.Name as 'APCompanyName',

p.PO, p.VendorGroup, p.Vendor, p.Description, p.OrderDate, 
p.OrderedBy, p.ExpDate, p.Status, p.JCCo, 
p.Job, 

p.Job as 'POHeaderJob',

p.INCo, p.Loc, 
p.ShipLoc, p.Address, p.City, p.State, p.Zip, p.Country, p.ShipIns, p.HoldCode, 
p.PayTerms, p.CompGroup, p.MthClosed, p.InUseMth, p.InUseBatchId, 
p.Approved, p.ApprovedBy, p.Purge, p.Notes, p.AddedMth, p.AddedBatchID, 
p.UniqueAttchID, p.Attention, p.PayAddressSeq, p.POAddressSeq, 
p.Address2, p.KeyID,
v.Name as 'VendorName',

case p.Status
	when 0 then 'Open'
	when 1 then 'Complete'
	when 2 then 'Closed'
	when 3 then 'Pending'
	else ''
end as 'StatusDescription',

p.City + ' ' + p.State + ' ' + p.Zip + ' ' + p.Country as 'CityAddress',

j.Description as 'POHeaderJobDescription'
	
from POHD p with (nolock)
	left join APVM v with (nolock) on p.VendorGroup = v.VendorGroup and p.Vendor = v.Vendor
	left join JCJM j with (nolock) on p.POCo = j.JCCo and p.Job = j.Job
	left join HQCO c with (nolock) on p.POCo = c.HQCo

where p.VendorGroup = IsNull(@VendorGroup, p.VendorGroup)
and p.Vendor = IsNull(@Vendor, p.Vendor)
and p.KeyID = IsNull(@KeyID, p.KeyID)
GO
GRANT EXECUTE ON  [dbo].[vpspAPMyPurchaseOrdersGet] TO [VCSPortal]
GO
