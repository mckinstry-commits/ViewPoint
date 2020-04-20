SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




/****** Object:  Stored Procedure dbo.vspRQQLApply    Script Date: 9/21/2004 9:37:58 AM ******/
    CREATE   procedure [dbo].[vspRQQLApply]
    /************************************************************************
    * CREATED:	DC 3/30/2006    
    * MODIFIED:    DC 12/4/08  #130129  -Combine RQ and PO into a single module
    *
    * Purpose of Stored Procedure
    *
    *	Apply changes to all RQQL passed in
    *    
    *
    *           
    * Used In:
    *	RQQuoteEntry
    *
    * returns 0 if successfull 
    * returns 1 and error msg if failed
    *
    *************************************************************************/
        (@rqco bCompany, @quoteid bRQ, @vendorgrp bGroup = null, @vendor bVendor = null,
    	@shiploc bLoc = null, @status tinyint = null, @msg varchar(255) output)
    
    as
    set nocount on
    
    declare @rcode int,
			@locked bYN,
			@count1 as int,
			@count2 as int

    SELECT @rcode = 0

	if @rqco is null
		begin
		SELECT @msg = 'Missing PO Company', @rcode = 1
		GOTO bspexit
		end

	if @quoteid is null
		begin
		SELECT @msg = 'Missing RQ Quote ID', @rcode = 1
		GOTO bspexit
		end		    	  

	-- total number of RQRL that are on this rq
	select @locked = Locked from RQQH WHERE RQCo = @rqco AND Quote = @quoteid

	IF @locked = 'Y'
		begin
		SELECT @msg = 'Quote header is Locked.  Cannot update Quote Lines', @rcode = 1
		GOTO bspexit
		end		    	
  
   	-- total number of RQQL to be updated
   	select @count1 = count(1) from RQQL WHERE RQCo = @rqco	AND Quote = @quoteid
   
   	-- total number of RQQL that have a status of Complete or Denied.
   	select @count2 = count(1) from RQQL WHERE RQCo = @rqco	AND Quote = @quoteid AND (Status = 4 or Status = 5)

   	if @count2 = @count1
   		BEGIN
   		SELECT @msg = 'No Quote Lines updated because all Quote Lines have a status of completed and/or denied', @rcode = 1
   		GOTO bspexit
   		END

   	IF @count2 > 0
   		BEGIN
   		SELECT @msg = 'Some Quote Lines cannot be updated because they have a status of completed and/or denied', @rcode = 0
   		END
 
	UPDATE RQQL
	Set VendorGroup = isnull(@vendorgrp,VendorGroup),
		Vendor = isnull(@vendor, Vendor),
		ShipLoc = isnull(@shiploc, ShipLoc),
		Status = isnull(@status,Status)
	WHERE RQCo = @rqco
			AND Quote = @quoteid 
			AND Status <> 4
			AND Status <> 5
			
	if @@ERROR  <> 0
		BEGIN
		SELECT @msg = 'SQL ERROR:  Could not update RQQL', @rcode = 1
		GOTO bspexit
		END

    
    
    bspexit:
    IF @rcode<>0 select @msg=@msg + char(13) + char(10) + '[vspRQQLApply]'
    RETURN @rcode
    
 





GO
GRANT EXECUTE ON  [dbo].[vspRQQLApply] TO [public]
GO
