SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPOpenTransOnHoldCheck    Script Date: 8/28/99 9:34:01 AM ******/
    CREATE  procedure [dbo].[bspAPOpenTransOnHoldCheck]
    
       
    /***********************************************************
     * CREATED BY: EN 1/30/98
     * MODIFIED By : EN 4/3/98
     *              kb 10/28/2 - issue #18878 - fix double quotes
	 *				MV 03/05/09 - #132482 - Don't validate HQHC when checking
	 *					for hold code in open transactions.  
					AR 11/29/10 - #142278 - removing old style joins replace with ANSI correct form
     *
     * USAGE:
     * Verify existence of open AP transactions for a specified vendor which are
     * on hold for the specified hold code and return a flag indicating the results.
     * An error is returned if anything goes wrong.             
     * 
     *  INPUT PARAMETERS
     *   @apco	AP company number
     *   @vendorgrp	vendor group
     *   @vendr	vendor number 
     *   @holdcode	hold code 
     *
     * OUTPUT PARAMETERS
     *   @msg      'Y' if open trans found; 'N' if not; error message if error occurs 
     *
     * RETURN VALUE
     *   0   success
     *   1   fail
    *******************************************************************/ 
    (@apco bCompany, @vendorgrp bGroup, @vendr bVendor, @holdcode bHoldCode, @msg varchar(90) output)
    as
    set nocount on
    
    declare @rcode int
    
    select @rcode=0
    
    /* validate Vendor Group/Vendor Code */
    if not exists (select * from APVM where VendorGroup=@vendorgrp and Vendor=@vendr)
    	begin
        	select @msg = 'Invalid Vendor Code!', @rcode = 1
        	goto bspexit
       	end
    
    /* validate Hold Code */
--    if not exists (select * from HQHC where HoldCode=@holdcode)
--    	begin
--        	select @msg = 'Invalid Hold Code!', @rcode = 1
--        	goto bspexit
--       	end
    
    /* validate Vendor Hold Code */
    if not exists (select * from APVH where APCo=@apco and VendorGroup=@vendorgrp 
    		and Vendor=@vendr and HoldCode=@holdcode)
    	begin
        	select @msg = 'Invalid Vendor Hold Code!', @rcode = 1
        	goto bspexit
       	end
    
    /* check for open transactions */
    select @msg = 'N'
    
    --#142278
    IF EXISTS ( SELECT  *
                FROM    dbo.bAPTH h
                        JOIN dbo.bAPTD d ON	h.APCo = d.APCo
											AND h.Mth = d.Mth
											AND h.APTrans = d.APTrans
                        JOIN dbo.bAPHD o ON	d.APCo = o.APCo
											AND d.Mth = o.Mth
											AND d.APTrans = o.APTrans
											AND d.APLine = o.APLine
											AND d.APSeq = o.APSeq
                WHERE   h.APCo = @apco
                        AND h.VendorGroup = @vendorgrp
                        AND h.Vendor = @vendr
                        AND h.InUseBatchId IS NULL
                        AND h.PrePaidChk IS NULL
                        AND d.[Status] NOT IN (3,4)
                        AND o.HoldCode = @holdcode 
                 ) 
        BEGIN
			SELECT  @msg = 'Y'
		END
    	
    
    bspexit:
    
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPOpenTransOnHoldCheck] TO [public]
GO
