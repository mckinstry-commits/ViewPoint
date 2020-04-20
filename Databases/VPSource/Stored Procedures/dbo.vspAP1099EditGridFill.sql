SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspAP1099EditGridFill]
  
/***********************************************************
* CREATED BY: MV 11/02/05
* MODIFIED By : GG 03/08/06 - change query to remove distinct and order by Mth, APTrans
*				MV 02/02/07 - #123636 - subtract DiscTaken from Amt Paid in Year calculation
*		
* Usage:
*	Used by AP1099Edit form to get APTH records to fill the form grid 
*
* Input params:
*	@apco			company
*	@yemo			year ending month
*	@vendorgroup	
*	@vendor
*	@mth
*	@usepaidmthyn   flag to use APTH ExpMth or APTD PaidMth
*
* Output params:
*	@msg		error message
*
* Return code:
*	0 = success, 1 = failure
*****************************************************/
  (@apco bCompany ,@yemo bMonth, @vendorgroup bGroup, @vendor bVendor, @mth bMonth,
	@usepaidmthyn bYN, @msg varchar(255)=null output)

  as
  set nocount on
  declare @rcode int
  select @rcode = 0
  /* check required input params */
  if @apco is null
  	begin
  	select @msg = 'Missing Company.', @rcode = 1
  	goto bspexit
  	end
  
  if @vendorgroup is null
  	begin
  	select @msg = 'Missing Vendor Group.', @rcode = 1
  	goto bspexit
  	end

 if @vendor is null
  	begin
  	select @msg = 'Missing Vendor.', @rcode = 1
  	goto bspexit
  	end
  
if @mth is null
  	begin
  	select @msg = 'Missing Month.', @rcode = 1
  	goto bspexit
  	end


select 'AP Trans' = h.APTrans,
	'Exp Mth'=convert(varchar(2),MONTH(h.Mth)) + '/' + RIGHT(convert(varchar(4),YEAR(h.Mth)),2),
	'AP Ref' = h.APRef,
	'Description' = Description,
	'Inv Date' = convert(varchar,InvDate,1),
	'Amt Paid in Year' = isnull((select sum(d2.Amount - d2.DiscTaken)
							from dbo.APTD d2 (nolock)
							where d2.APCo = h.APCo and d2.Mth = h.Mth and d2.APTrans = h.APTrans
								and d2.CMRef is not null and datepart(year,d2.PaidMth) = datepart(year,@yemo)),0),
	'Multi Pay' = isnull((select case when count(distinct(d3.CMRef))> 1 then 'Y' else 'N' end 
						from dbo.APTD d3 (nolock)
						where h.APCo=d3.APCo and h.Mth=d3.Mth and h.APTrans=d3.APTrans and d3.CMRef is not null),'N'),
	'1099' = V1099YN,
	'Type' = V1099Type,
	'Box#' = V1099Box
from dbo.bAPTH h (nolock)
where h.APCo = @apco and h.VendorGroup = @vendorgroup and h.Vendor = @vendor and h.InUseBatchId is null and
	exists(select top 1 1 from dbo.bAPTD d (nolock)
			where d.APCo = h.APCo and d.Mth = h.Mth and d.APTrans = h.APTrans
				and case isnull(@usepaidmthyn,'N') when 'Y' then d.PaidMth else h.Mth end = @mth) 
order by h.Mth, h.APTrans

bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAP1099EditGridFill] TO [public]
GO
