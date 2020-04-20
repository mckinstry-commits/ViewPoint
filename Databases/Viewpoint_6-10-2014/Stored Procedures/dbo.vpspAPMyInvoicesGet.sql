SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspAPMyInvoicesGet]
/************************************************************
* CREATED:		7/19/07		CHS
* Modified:		11/27/07	CHS
*		        03/26/08    TJL - Issue #127347, International Address
*               8/08/12     DanW (via Tom J) Cleans up the get proc so that it handles getting a single record and handle nulls
* USAGE:
*   gets AP Invoices
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
	
Select 
h.APCo, 
c.Name as 'APCompanyName',

h.Mth, h.APTrans, h.VendorGroup, h.Vendor, h.InvId, h.APRef, 
h.Description, h.InvDate, h.DiscDate, h.DueDate, h.InvTotal, h.HoldCode, 
h.PayControl, h.PayMethod, h.CMCo, h.CMAcct, h.PrePaidYN, h.PrePaidMth, 
h.PrePaidDate, h.PrePaidChk, h.PrePaidSeq, h.PrePaidProcYN, h.V1099YN, 
h.V1099Type, h.V1099Box, h.PayOverrideYN, h.PayName, h.PayAddress, h.PayCity, 
h.PayState, h.PayZip, h.PayCountry, h.OpenYN, h.InUseMth, h.InUseBatchId, h.BatchId, 
h.Purge, h.InPayControl, h.PayAddInfo, h.DocName, h.AddendaTypeId, h.PRCo, 
h.Employee, h.DLcode, h.TaxFormCode, h.TaxPeriodEndDate, h.AmountType, 
h.Amount, h.AmtType2, h.Amount2, h.AmtType3, h.Amount3, h.SeparatePayYN, 
h.ChkRev, cast(h.Notes as varchar(2048)) as 'Notes', 
h.UniqueAttchID, h.AddressSeq, h.KeyID,

(select isnull(sum(APTD.Amount), 0)
	from APTD with (nolock) 
	where 
		h.APCo = APTD.APCo 
		and h.Mth = APTD.Mth 
		and h.APTrans = APTD.APTrans)  as 'Gross',

(select isnull(sum(APTD.Amount), 0)
	from APTD with (nolock) 
	where 
		h.APCo = APTD.APCo 
		and h.Mth = APTD.Mth 
		and h.APTrans = APTD.APTrans 
		and APTD.Status < 3)  as 'Payable',

(select isnull(sum(APTD.DiscOffer), 0)
	from APTD with (nolock) 
	where 
		h.APCo = APTD.APCo 
		and h.Mth = APTD.Mth 
		and h.APTrans = APTD.APTrans 
		and APTD.Status < 3)  as 'Discount',


(select isnull(sum(APTD.Amount), 0)
	from APTD with (nolock) 
	where 
		h.APCo = APTD.APCo 
		and h.Mth = APTD.Mth 
		and h.APTrans = APTD.APTrans 
		and APTD.Status < 3) - 
(select isnull(sum(APTD.DiscOffer), 0)
	from APTD with (nolock) 
	where 
		h.APCo = APTD.APCo 
		and h.Mth = APTD.Mth 
		and h.APTrans = APTD.APTrans 
		and APTD.Status < 3) as 'Net' 

from APTH h with (nolock)
	left join HQCO c with (nolock) on h.APCo = c.HQCo

where h.Vendor = IsNull(@Vendor, h.Vendor) 
	and h.VendorGroup = IsNull(@VendorGroup, h.VendorGroup) 
	and h.OpenYN = 'Y'
	and h.KeyID = IsNull(@KeyID, h.KeyID)
	
union

Select 
h.APCo, 
c.Name as 'APCompanyName',
h.Mth, h.APTrans, h.VendorGroup, h.Vendor, h.InvId, h.APRef, 
h.Description, h.InvDate, h.DiscDate, h.DueDate, h.InvTotal, h.HoldCode, 
h.PayControl, h.PayMethod, h.CMCo, h.CMAcct, h.PrePaidYN, h.PrePaidMth, 
h.PrePaidDate, h.PrePaidChk, h.PrePaidSeq, h.PrePaidProcYN, h.V1099YN, 
h.V1099Type, h.V1099Box, h.PayOverrideYN, h.PayName, h.PayAddress, h.PayCity, 
h.PayState, h.PayZip, h.PayCountry, h.OpenYN, h.InUseMth, h.InUseBatchId, h.BatchId, 
h.Purge, h.InPayControl, h.PayAddInfo, h.DocName, h.AddendaTypeId, h.PRCo, 
h.Employee, h.DLcode, h.TaxFormCode, h.TaxPeriodEndDate, h.AmountType, 
h.Amount, h.AmtType2, h.Amount2, h.AmtType3, h.Amount3, h.SeparatePayYN, 
h.ChkRev, cast(h.Notes as varchar(2048)) as 'Notes',   
h.UniqueAttchID, h.AddressSeq, h.KeyID,

(select isnull(sum(APTD.Amount), 0)
	from APTD with (nolock) 
	where 
		h.APCo = APTD.APCo 
		and h.Mth = APTD.Mth 
		and h.APTrans = APTD.APTrans)  as 'Gross',

(select isnull(sum(APTD.Amount), 0)
	from APTD with (nolock) 
	where 
		h.APCo = APTD.APCo 
		and h.Mth = APTD.Mth 
		and h.APTrans = APTD.APTrans 
		and APTD.Status < 3)  as 'Payable',

(select isnull(sum(APTD.DiscOffer), 0)
	from APTD with (nolock) 
	where 
		h.APCo = APTD.APCo 
		and h.Mth = APTD.Mth 
		and h.APTrans = APTD.APTrans 
		and APTD.Status < 3)  as 'Discount',


(select isnull(sum(APTD.Amount), 0)
	from APTD with (nolock) 
	where 
		h.APCo = APTD.APCo 
		and h.Mth = APTD.Mth 
		and h.APTrans = APTD.APTrans 
		and APTD.Status < 3) - 
	(select isnull(sum(APTD.DiscOffer), 0)
		from APTD with (nolock) 
		where 
			h.APCo = APTD.APCo 
			and h.Mth = APTD.Mth 
			and h.APTrans = APTD.APTrans 
			and APTD.Status < 3) as 'Net' 

from APTH h with (nolock)
	left join APTD d with (nolock) on h.APCo = d.APCo and h.APTrans = d.APTrans
	left join HQCO c with (nolock) on h.APCo = c.HQCo

where h.Vendor = IsNull(@Vendor, h.Vendor)  
	and h.VendorGroup = IsNull(@VendorGroup, h.VendorGroup) 
	and h.OpenYN = 'N'
	and d.PaidDate > dateadd(dd, -60, getdate())	
	and h.KeyID = IsNull(@KeyID, h.KeyID)
GO
GRANT EXECUTE ON  [dbo].[vpspAPMyInvoicesGet] TO [VCSPortal]
GO
