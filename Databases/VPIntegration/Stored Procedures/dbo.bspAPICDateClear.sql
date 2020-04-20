SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspAPICDateClear]
   /*************************************
   * CREATED BY    : MAV  07/10/2003 for Issue #15528
   * LAST MODIFIED : 
   *
   * Clears ICRptDate from bAPFT and bAPVM
   *
   * Pass:
   *	APCompany, IC Report date
   *
   * Returns:
   *	
   *
   * Success returns:
   *   0
   *
   * Error returns:
   *	1 
   **************************************/
   (@APCo bCompany, @ICRptDate bDate, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @vendorgroup int
   
   select @rcode = 0
   select @vendorgroup = VendorGroup from bHQCO with (nolock) where HQCo=@APCo
   if @@rowcount = 0
   		begin
   		select @msg = 'Invalid Company', @rcode=1
   		end
   -- clear IC report date from Federal Totals	
   update bAPFT set ICRptDate = null 
   	where APCo=@APCo and ICRptDate = @ICRptDate
   	if @@rowcount = 0
   		begin
   		select @msg = 'IC Report Date was not cleared in bAPFT ', @rcode=1
   		end
   --clear IC report date from vendors
   update bAPVM set ICLastRptDate = null 
   	where VendorGroup = @vendorgroup and ICLastRptDate = @ICRptDate
   	if @@rowcount = 0
   		begin
   		select @msg = 'IC Report Date was not cleared in bAPVM ', @rcode=1
   		end
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPICDateClear] TO [public]
GO
