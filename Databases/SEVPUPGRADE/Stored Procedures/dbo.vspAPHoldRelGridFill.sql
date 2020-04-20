SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspAPHoldRelGridFill]
/***********************************************************
* CREATED: MV 02/16/10
* MODIFIED: 
*
* USAGE:
* Selects bAPHR to return data to the form to fill the grid.
*
*  INPUT PARAMETERS
*   @apco	AP company number
*	@userid user login
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
*
* RETURN VALUE
*   0   success
*   1   fail
**************************************************************/
	(@apco bCompany = 0,@userid bVPUserName, @total bDollar output)
          
as
set nocount on

-- GRID FILL SELECT 
select 'APCo' = r.APCo,
'Mth' = convert(varchar(2),MONTH(r.Mth)) + '/' + RIGHT(convert(varchar(4),YEAR(r.Mth)),2),
'APTrans' = r.APTrans,
'APLine' = r.APLine,
'APSeq' = r.APSeq,
'Vendor' = h.Vendor,
'Name' = v.Name,
'APRef' = h.APRef,
'PayType' = r.PayType,
'Amount' = r.Amount
from APHR r 
join APTH h on r.APCo=h.APCo and r.Mth=h.Mth and r.APTrans=h.APTrans 
join APVM v on h.VendorGroup=v.VendorGroup and h.Vendor=v.Vendor
where r.UserId=@userid
order by r.Mth, h.Vendor, h.APRef

select @total = sum(r.Amount)
from APHR r 
join APTH h on r.APCo=h.APCo and r.Mth=h.Mth and r.APTrans=h.APTrans 
join APVM v on h.VendorGroup=v.VendorGroup and h.Vendor=v.Vendor
where r.UserId=@userid
      


GO
GRANT EXECUTE ON  [dbo].[vspAPHoldRelGridFill] TO [public]
GO
