SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspAPMyPurchaseOrderComplianceGet]
/************************************************************
* CREATED:     8/2/07      CHS
*MODIFIED:     07/27/2011  TRL TK-07143  Expand bPO parameters/varialbles to varchar(30)
*              8/08/12     DanW (via Tom J) Cleans up the get proc so that it handles getting a single record and handle nulls
* USAGE:
*   gets AP Purchase Order Compliance
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
	
	
Select 
c.POCo, c.PO, c.CompCode, c.Seq, c.VendorGroup, c.Vendor, c.Description, 
c.Verify, c.ExpDate, c.Complied, c.Notes, c.PurgeYN, c.UniqueAttchID, c.KeyID,
v.Name as 'VendorName',

case c.Verify
	when 'Y' then 'Yes'
	when 'N' then 'No'
	else ''
end as 'VerifyYesNo',

case c.Complied
	when 'Y' then 'Yes'
	when 'N' then 'No'
	else ''
end as 'CompliedYesNo'

from POCT c with (nolock) 
	left join APVM v with (nolock) on c.VendorGroup = v.VendorGroup and c.Vendor = v.Vendor
	
where c.POCo = IsNull(@POCo, c.POCo)
  and c.PO = IsNull(@PO, c.PO)
  and c.KeyID = IsNull(@KeyID, c.KeyID)
GO
GRANT EXECUTE ON  [dbo].[vpspAPMyPurchaseOrderComplianceGet] TO [VCSPortal]
GO
