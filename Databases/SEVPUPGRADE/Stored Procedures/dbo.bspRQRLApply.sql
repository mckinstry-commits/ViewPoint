SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspRQRLApply    Script Date: 9/21/2004 9:37:58 AM ******/
    CREATE             procedure [dbo].[bspRQRLApply]
    /************************************************************************
    * CREATED:	DC 9/21/04    
    * MODIFIED:    DC 1/04/05 - 26685
    * 				DC 4/11/05 - 28354 - Creating multiple PO's when there should only be one; difference when using F4.
	*				DC 03/07/08 - Issue #127075:  Modify PO/RQ  for International addresses
	*
    *
    * Purpose of Stored Procedure
    *
    *	Apply changes to all RQRL passed in
    *    
    *
    *           
    * Used In:
    *	RQLineApply
    *
    * returns 0 if successfull 
    * returns 1 and error msg if failed
    *
    *************************************************************************/
        (@rqco bCompany, @rqid bRQ, @vendorgrp bGroup = null, @vendor bVendor = null,
    	@shiploc bLoc = null, @reqdate bDate = null, @route int = null, @msg varchar(255) output)
    
    as
    set nocount on
    
        declare @rcode int,
    			@address varchar(60),
     			@city varchar(30), 
    			@state varchar(4), 
    			@zip bZip,
				@country varchar(2),  --DC #127075
     			@taxcode bTaxCode, 
    			@address2 varchar(60),
    			@poslmsg varchar(255),
   			@count1 int, --DC 26685
   			@count2 int --DC 26685
    
        SELECT @rcode = 0
    
    	if @rqco is null
    		begin
    		SELECT @msg = 'Missing RQ Company', @rcode = 1
    		GOTO bspexit
    		end
    
    	if @rqid is null
    		begin
    		SELECT @msg = 'Missing RQ ID', @rcode = 1
    		GOTO bspexit
    		end
    	
    	if @shiploc is not null
    		begin
    		exec @rcode = bspPOSLVal @rqco,@shiploc,@address output,@city output, @state output, @zip output,
     				@taxcode output, @address2 output, @country output, @poslmsg output		
   
   			--DC 28354 -----------START----------------
   			IF @address = ''
   				SET @address = NULL
	   		
   			IF @city = ''
   				SET @city = NULL
	   		
   			IF @state = ''
   				SET @state = NULL
	   		
   			IF @zip = ''
   				SET @zip = NULL
	   		
   			IF @address2 = ''
   				SET @address = null

   			IF @country = ''
   				SET @country = null

    		END
   			------------------END---------------------- 
   
   	--DC 26685
   	-- total number of RQRL that are on a quote or po
   	select @count1 = count(1) from RQRL WHERE RQCo = @rqco	AND RQID = @rqid AND (PO is NOT NULL or Quote is NOT NULL)
   
   	-- total number of RQRL that are on this rq
   	select @count2 = count(1) from RQRL WHERE RQCo = @rqco	AND RQID = @rqid
   
   	if @count2 = @count1
   		BEGIN
   		SELECT @msg = 'No Requisitions updated because they are on a Quote or PO', @rcode = 1
   		GOTO bspexit
   		END
   
   	IF @count1 > 0
   		BEGIN
   		SELECT @msg = 'Some Requisitions cannot be updated because they are on a Quote or PO', @rcode = 0
   		END
   		
    	UPDATE RQRL
    	Set VendorGroup = isnull(@vendorgrp,VendorGroup),
    		Vendor = isnull(@vendor, Vendor),
    		ShipLoc = isnull(@shiploc, ShipLoc),
    		ReqDate = isnull(@reqdate,ReqDate),
    		Route = isnull(@route, Route),
    		Address = isnull(@address,Address),
    		City = isnull(@city, City),
    		State = isnull(@state, State),
    		Zip = isnull(@zip,Zip),
    		Address2 = isnull(@address2, Address2),
			Country = isnull(@country, Country)
    	WHERE RQCo = @rqco
    			AND RQID = @rqid
   			AND PO is NULL  --DC 26685
   			AND Quote is NULL  -- DC 26685
    			
    	if @@ERROR  <> 0
    		BEGIN
    		SELECT @msg = 'SQL ERROR:  Could not update RQRL', @rcode = 1
    		GOTO bspexit
    		END
    
    
    bspexit:
    IF @rcode<>0 select @msg=@msg + char(13) + char(10) + '[bspRQRLApply]'
    RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspRQRLApply] TO [public]
GO
