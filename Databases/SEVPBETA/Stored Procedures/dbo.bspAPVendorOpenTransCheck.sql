SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPVendorOpenTransCheck    Script Date: 8/28/99 9:32:34 AM ******/
CREATE PROCEDURE [dbo].[bspAPVendorOpenTransCheck]
   
      
   /***********************************************************
    * CREATED BY: EN 1/30/98
    * MODIFIED By : EN 4/3/98
    *              kb 10/29/2 - issue #18878 - fix double quotes
					AR 11/29/10 - #142278 - removing old style joins replace with ANSI correct form
    *
    * USAGE:
    * Verify existence of open AP transactions for a specified vendor and
   
   
    * return a flag indicating the results.  An error is returned if anything
    * goes wrong.             
    * 
    *  INPUT PARAMETERS
    *   @apco	AP company number
    *   @vendorgrp	vendor group
    *   @vendr	vendor number  
    *
    * OUTPUT PARAMETERS
    *   @msg      'Y' if open trans found; 'N' if not; error message if error occurs 
    *
    * RETURN VALUE
    *   0   success
    *   1   fail
   *******************************************************************/
(
  @apco bCompany,
  @vendorgrp bGroup,
  @vendr bVendor,
  @msg varchar(90) OUTPUT
)
AS 
SET nocount ON
   
DECLARE @rcode int
   
SELECT  @rcode = 0
   
   /* validate Vendor Group/Vendor Code */
IF NOT EXISTS ( SELECT  *
                FROM    APVM
                WHERE   VendorGroup = @vendorgrp
                        AND Vendor = @vendr ) 
    BEGIN
        SELECT  @msg = 'Invalid Vendor Code!',
                @rcode = 1
        GOTO bspexit
    END
   
   /* check for open transactions */
SELECT  @msg = 'N'
-- #142278
IF EXISTS ( SELECT  *
            FROM    dbo.APTH h
                    JOIN dbo.APTD d ON h.APCo = d.APCo
										AND h.Mth = d.Mth
										AND h.APTrans = d.APTrans
            WHERE   h.APCo = @apco
                    AND h.VendorGroup = @vendorgrp
                    AND h.Vendor = @vendr
                    AND h.InUseBatchId IS NULL
                    AND h.PrePaidChk IS NULL
                    AND d.[Status] NOT IN(3,4) 
           )
    SELECT  @msg = 'Y'
   	
   
bspexit:
   
RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPVendorOpenTransCheck] TO [public]
GO
