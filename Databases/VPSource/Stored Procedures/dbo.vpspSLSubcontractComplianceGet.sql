SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspSLSubcontractComplianceGet]
/************************************************************
* CREATED:		3/13/07		CHS
* Modified:		12/4/07		CHS
* Modified:		1/2/08		CHS
*				GF 06/25/2010 - expanded SL to varchar(30)
*
* USAGE:
*   gets Subcontract Compliance info
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    SLCo and SL
*
************************************************************/
(@SLCo bCompany, @SL VARCHAR(30), @VendorGroup bGroup, @Vendor bVendor,
	@KeyID int = Null)

AS
SET NOCOUNT ON;

select
c.SLCo, c.SL, c.CompCode, c.Seq, c.VendorGroup,
v.Vendor, v.Name as 'VendorName', 

c.Description, c.Verify, 

case c.Verify
	when 'Y' then 'Yes'
	when 'N' then 'No'
	else '' 
	end as 'VerifyYesNo',

c.ExpDate,
c.Complied,

case c.Complied
	when 'Y' then 'Yes'
	when 'N' then 'No'
	else '' 
	end as 'CompliedYesNo',
	
c.Notes, c.ReceiveDate, c.Limit, c.PurgeYN,
c.UniqueAttchID, m.Memo,

c.Notes as 'SubComplNotes',
c.KeyID

from SLCT c with (nolock)
	join SLHD h with (nolock) on c.SLCo = h.SLCo and c.SL = h.SL
	left join APVM v with (nolock) on h.VendorGroup = v.VendorGroup and h.Vendor = v.Vendor
	left join APVC m with (nolock) on  m.APCo = h.SLCo
										and m.VendorGroup = h.VendorGroup 
										and m.Vendor = h.Vendor
										and m.CompCode = c.CompCode 


where c.SLCo = @SLCo and c.SL = @SL
and c.KeyID = IsNull(@KeyID, c.KeyID)

order by c.CompCode, c.Seq

GO
GRANT EXECUTE ON  [dbo].[vpspSLSubcontractComplianceGet] TO [VCSPortal]
GO
