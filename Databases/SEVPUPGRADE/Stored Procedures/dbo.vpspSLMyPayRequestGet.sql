SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspSLMyPayRequestGet]
/************************************************************
* CREATED:		4/9/07	CHS
* MODIFIED:		5/31/07	chs
* MODIFIED:		6/7/07	CHS
* MODIFIED:		6/25/07	chs
* MODIFIED:		7/11/07	chs
*
* USAGE:
*   gets pay request Headers
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

select h.KeyID, 
h.SLCo, h.UserName, h.SL, h.JCCo, h.Job, h.Description,
h.VendorGroup, h.Vendor, h.PayControl, h.APRef, h.InvDescription,
h.InvDate, h.PayTerms, h.DueDate, h.CMCo, h.CMAcct, h.HoldCode,
h.ReadyYN, 

case h.ReadyYN
	when 'Y' then 'Yes'
	when 'N' then 'No'
	else ''
	end as 'ReadyYesNo',

h.UniqueAttchID, 

convert(varchar(2048), h.Notes) as 'Notes',

isnull(sum(i.CurCost), 0) as 'CurCost',
(isnull(sum(i.PrevWCCost), 0) + isnull(sum(i.PrevSM), 0)) as 'PrevInvoiced',
isnull(sum(i.WCCost), 0) as 'WorkCompleted',

(isnull(sum(i.Purchased), 0) - isnull(sum(i.Installed), 0)) as 'StoredMaterials',

(isnull(sum(i.WCCost), 0) + isnull(sum(i.Purchased), 0) - isnull(sum(i.Installed), 0)) as 'Total',
(isnull(sum(i.WCRetAmt), 0) + isnull(sum(i.SMRetAmt), 0)) as 'Retainage',
isnull(sum(i.WCToDate), 0) as 'ToDate',

v.Name as 'VendorName' 

from SLWH h with (nolock)
	left join SLWI i with (nolock) on h.SLCo = i.SLCo and h.SL = i.SL
	left join APVM v with (nolock) on h.VendorGroup = v.VendorGroup and h.Vendor = v.Vendor
	
where h.JCCo = @JCCo and h.Job = @Job and h.Vendor = @Vendor 
and h.VendorGroup = @VendorGroup and ReadyYN != 'Y'
and h.KeyID = IsNull(@KeyID, h.KeyID)

group by h.KeyID, h.SLCo, h.SL, h.JCCo, h.Job, h.Description, h.VendorGroup, h.Vendor, 
h.UserName, h.PayControl, h.APRef, h.InvDescription, h.InvDate, h.PayTerms,
h.DueDate, h.CMCo, h.CMAcct, h.HoldCode, h.ReadyYN, h.UniqueAttchID, 
convert(varchar(2048), h.Notes), v.Name

GO
GRANT EXECUTE ON  [dbo].[vpspSLMyPayRequestGet] TO [VCSPortal]
GO
