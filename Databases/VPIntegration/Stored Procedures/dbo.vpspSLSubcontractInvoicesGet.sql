SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspSLSubcontractInvoicesGet]
/************************************************************
* CREATED:      3/13/07 CHS
* MODIFIED:		3/22/07 chs
* MODIFIED:		3/29/07 chs
* MODIFIED:		5/1/07 chs
* MODIFIED:		5/23/07 chs -- #124134
* MODIFIED:		12/3/07 chs -- #126352
*				06/25/2010 GF - ISSUE #135813 expanded SL to varchar(30)
*
* USAGE:
*   gets Subcontract Invoices
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    SLCo and SL
*
************************************************************/
(@SL VARCHAR(30), @Vendor bVendor, @VendorGroup bGroup,
	@KeyID int = Null)


AS
SET NOCOUNT ON;

select distinct
i.APCo, i.Mth, i.APTrans, i.APLine, i.SL, i.Description, 

h.Description as 'HeaderDescription', 

sum(i.GrossAmt) as 'GrossAmt', 

sum(i.Units) as 'InvoicedUnits',

h.APRef, h.InvDate, 

convert(varchar(2048), h.Notes),
convert(varchar(2048), h.Notes) as 'SubInvoiceNotes',

i.KeyID



from APTL i with (nolock)
	left join APTH h with (nolock) on 
		i.APCo = h.APCo and i.Mth = h.Mth and i.APTrans = h.APTrans

where i.SL = @SL and h.Vendor = @Vendor and h.VendorGroup = @VendorGroup
			and i.KeyID = IsNull(@KeyID, i.KeyID)

group by 
i.APCo, i.Mth, i.APTrans, i.APLine, convert(varchar(2048), h.Notes),
i.KeyID, h.APRef, i.SL, h.InvDate, i.Description, h.Description
GO
GRANT EXECUTE ON  [dbo].[vpspSLSubcontractInvoicesGet] TO [VCSPortal]
GO
