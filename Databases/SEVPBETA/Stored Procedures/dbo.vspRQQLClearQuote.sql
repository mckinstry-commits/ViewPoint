SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




/****** Object:  Stored Procedure dbo.vspRQQLClearQuote    Script Date: 07/03/2007 9:37:58 AM ******/
    CREATE   procedure [dbo].[vspRQQLClearQuote]
    /************************************************************************
    * CREATED:	DC 07/03/2007   
    * MODIFIED:    
    *
    * Purpose of Stored Procedure
    *
    *	Clear the Quote # and Quote Line # from RQRL record for all 
	*	Req's on the passed in Quote
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
        (@rqco bCompany, @quote int, @quoteline int, 
		@msg varchar(255) output)
    
    as
    set nocount on
    
    declare @rcode int,
			@locked bYN,
			@count1 as int,
			@count2 as int

    SELECT @rcode = 0

	if @rqco is null
		begin
		SELECT @msg = 'Missing RQ Company', @rcode = 1
		GOTO vspexit
		end

	if @quote is null
		begin
		SELECT @msg = 'Missing Quote ID', @rcode = 1
		GOTO vspexit
		end		    	  

	if @quoteline is null
		begin
		SELECT @msg = 'Missing RQ Quote Line ID', @rcode = 1
		GOTO vspexit
		end		    	  

	-- check to see if this quote is locked.
	select @locked = Locked from RQQH WHERE RQCo = @rqco AND Quote = @quote
	IF @locked = 'Y'
		begin
		SELECT @msg = 'Quote header is Locked.  Cannot update Quote Lines', @rcode = 1
		GOTO vspexit
		end		    	
  
   	-- check to see if the quote has been completed.
   	select top 1 1 from RQQL WHERE RQCo = @rqco AND Quote = @quote AND QuoteLine = @quoteline AND Status = 4
	if @@Rowcount >0 
   		BEGIN
   		SELECT @msg = 'Quote Line cannot be updated because the status is Completed', @rcode = 0
		goto vspexit   		
		END
 
	UPDATE RQRL
	Set Quote = null,
		QuoteLine = null
	WHERE RQCo = @rqco
			AND Quote = @quote
			AND QuoteLine =  @quoteline
			AND Status <> 5
			
	if @@ERROR  <> 0
		BEGIN
		SELECT @msg = 'SQL ERROR:  Could not update RQRL', @rcode = 1
		GOTO vspexit
		END

    vspexit:
    IF @rcode<>0 select @msg=@msg + char(13) + char(10) + '[vspRQQLClearQuote]'
    RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[vspRQQLClearQuote] TO [public]
GO
