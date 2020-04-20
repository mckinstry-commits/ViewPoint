SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspAPICCheck]
   /*************************************
   * CREATED BY    : MAV  07/11/2003 for Issue #15528
   * LAST MODIFIED : 
   *
   * Checks if there are any independent contractors to report 
   * on for the current year
   *  
   *
   * Pass:
   *	APCompany
   *
   * Returns:
   *	ICcheckYN 
   *	'Y' = yes there are I.C.'s to report on
   *	'N' = there are no I.C.s to report on
   *
   * Success returns:
   *   0
   *
   * Error returns:
   *	1 
   **************************************/
   (@APCo bCompany, @ICcheckYN char(1)=null output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @year as varchar (4),@ICPayAmt bDollar
   
   select @rcode = 0
   SELECT @year = DATEPART(yy, GETDATE()) 
   select @ICPayAmt = isnull(ICPayAmt,0) from bAPCO with (nolock) where APCo=@APCo
   if @@rowcount = 0
   	begin
   	select @msg = 'Invalid AP Company', @rcode=1
   	goto bspexit
   	end
   
   select top 1 1 from bAPFT f
   	join bAPVM v on f.VendorGroup=v.VendorGroup and f.Vendor=v.Vendor
   	where f.APCo=@APCo and year(YEMO)= @year and f.V1099Type='MISC'
   	 and (isnull(Box1Amt,0) + isnull(Box2Amt,0) + isnull(Box3Amt,0) + isnull(Box4Amt,0) + isnull(Box5Amt,0) +
   		isnull(Box6Amt,0) + isnull(Box7Amt,0) + isnull(Box8Amt,0) + isnull(Box9Amt,0) + isnull(Box10Amt,0) + 
   		isnull(Box11Amt,0) + isnull(Box12Amt,0) + isnull(Box13Amt,0) + isnull(Box14Amt,0) + isnull(Box15Amt,0) +
   		isnull(Box16Amt,0) + isnull(Box17Amt,0) + isnull(Box18Amt,0))>=@ICPayAmt 
   		and f.ICRptDate is null 
   		and (v.ICSocSecNbr is not null or v.ICState is not null or v.ICZip is not null)
   	if @@rowcount > 0 select @ICcheckYN = 'Y' else select @ICcheckYN = 'N'
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPICCheck] TO [public]
GO
