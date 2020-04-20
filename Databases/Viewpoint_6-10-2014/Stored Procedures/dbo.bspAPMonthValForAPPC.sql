SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPMonthValForAPPC    Script Date: 8/28/99 9:32:32 AM ******/
   CREATE proc [dbo].[bspAPMonthValForAPPC]
   /***********************************************************
    * CREATED BY: EN 1/8/98
    * MODIFIED By: EN 4/3/98
    *              kb 10/28/2 - issue #18878 - fix double quotes
    			   AR 11/29/10 - #142278 - removing old style joins replace with ANSI correct form
    *
    * USAGE:
    * Validates that a specified vendor/month exists in APTH.  Used as month 
    * validation routine in AP Payment Control.
    * 
    * INPUT PARAMETERS
    *   @apco	AP Company
    *   @vendorgrp	Vendor group
    *   @vendr	Vendor number associated with transaction
    *   @mth	Month to validate
    *
    * OUTPUT PARAMETERS
    *   @msg 	If Error, return error message.
    * RETURN VALUE
    *   0   success
    *   1   fail
    ****************************************************************************************/ 
    (@apco bCompany, @vendorgrp bGroup=null, @vendr bVendor=null,
    	@mth bMonth, @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   	
   if @apco = 0
   	begin
   	select @msg = 'Missing AP Company#', @rcode=1
   	goto bspexit
   	end
   
   if @vendorgrp is null
   	begin
   	select @msg = 'Missing vendor group', @rcode=1
   	goto bspexit
   	end
   
   if @vendr is null
   	begin
   	select @msg = 'Missing vendor', @rcode=1
   	goto bspexit
   	end
   		
   if @mth is null
   	begin
   	select @msg = 'Missing Month' , @rcode=1
   	goto bspexit
   	end
   
   /* verify entry for month exists for selected vendor */
   --142278
   IF NOT EXISTS ( SELECT   *
                   FROM     dbo.APTH h
                            JOIN dbo.APTD d	ON h.APCo = d.APCo
											AND h.Mth = d.Mth  
											AND h.APTrans = d.APTrans
                   WHERE    h.APCo = @apco
                            AND h.Mth = @mth
                            AND h.VendorGroup = @vendorgrp
                            AND h.Vendor = @vendr
                            AND d.[Status] NOT IN (3,4)
                  ) 
    BEGIN
   
        SELECT  @msg = 'No transactions exist for this vendor and month!',
                @rcode = 1
        GOTO bspexit
    END
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPMonthValForAPPC] TO [public]
GO
