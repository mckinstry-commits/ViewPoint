SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspAPMyInvoiceLineDetailListGet]
/************************************************************
* CREATED:     7/19/07  CHS
*              8/08/12  DanW (via Tom J) Cleans up the get proc so that it handles getting a single record and handle nulls
* USAGE:
*   gets AP Invoice Line Details
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo and Job 
*
************************************************************/
(@APCo bCompany = Null, @Mth bMonth = Null, @APTrans bTrans = Null, @APLine smallint = Null, @KeyID int = Null)

AS
	SET NOCOUNT ON;
	
select
d.APCo, d.Mth, d.APTrans, d.APLine, d.APSeq, d.PayType, d.Amount, d.DiscOffer, 
d.DiscTaken, d.DueDate, d.Status, d.PaidMth, d.PaidDate, d.CMCo, d.CMAcct, 
d.PayMethod, d.CMRef, d.CMRefSeq, d.EFTSeq, d.VendorGroup, d.Supplier, 
d.PayCategory, d.KeyID,

p.Description as 'PayTypeDescription',

c.ClearDate as 'CMCLearDate',

case d.Status
	when 1 then 'Open'
	when 2 then 'Hold'
	when 3 then 'Paid'
	when 4 then 'Cleared'
	else ''
end as 'StatusDescription'

from APTD d with (nolock)
	left join APPT p with (nolock) on d.APCo = p.APCo and d.PayType = p.PayType
	left join CMDT c with (nolock) on d.CMCo = c.CMCo and d.CMAcct = c.CMAcct and d.CMRef = c.CMRef and d.CMRefSeq = c.CMRefSeq


where d.APCo = IsNull(@APCo, d.APCo)
  and d.Mth = IsNull(@Mth, d.Mth)
  and d.APTrans = IsNull(@APTrans, d.APTrans)
  and d.APLine = IsNull(@APLine, d.APLine)
  and d.KeyID = IsNull(@KeyID, d.KeyID)
GO
GRANT EXECUTE ON  [dbo].[vpspAPMyInvoiceLineDetailListGet] TO [VCSPortal]
GO
