SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspAPPayAddrUpdate]
/***********************************************************
* CREATED BY: MV 10/02/02
* MODIFIED BY: MV 10/25/02 - #18037 added AddressSeq  
*		MV 10/03/03 - #22647 don't validate state and zip.
*		TJL 03/26/08 - #127347 Intl addresses 
*
* USAGE:
* Called by AP Payment Address Override to update
* the Pay address fields in bAPTH.
*
* INPUT PARAMETERS
*  @co			AP Company
*  @mth			Month
*  @trans		APTrans
*  @addrseq		AddressSeq
*  @addrovryn	   PayOverrideYN
*  @name		   PayName
*  @addr		   PayAddress
*  @city		   PayCity
*  @state		   PayState
*  @zip	 		PayZip
*  @country		PayCountry
*  @addlinfo	PayAddInfo		
* OUTPUT PARAMETERS
*  @msg                error message if error occurs
*
* RETURN VALUE
*  0                   success
*  1                   failure
************************************************************/
     (@co bCompany,@mth bDate, @trans int,@addrseq int, @addrovryn bYN, @name varchar (60),
    	@addr varchar(60), @city varchar (60), @state varchar(4), @zip bZip, @country char(2),
    	@addlinfo varchar(60),@msg varchar(255) output)
       as
    
       set nocount on
    
       declare @rcode int, @errmsg varchar (100)
    
       select @rcode = 0
    
       if @co is null	 
         begin
         select @msg = 'Missing APCompany!', @rcode = 1
         goto bspexit
         end
    
        if @mth is null	 
         begin
         select @msg = 'Missing Month!', @rcode = 1
         goto bspexit
         end
    
         if @trans is null	
         begin
         select @msg = 'Missing APTrans!', @rcode = 1
         goto bspexit
         end
   
    -- 22647 - let em enter blank state and zip.
    /*if @addrovryn='Y'
    	begin
    		if @state is null
    		begin
    		select @msg = 'Missing State!', @rcode = 1
    		goto bspexit
    		end
    		
    		if @zip is null
    		begin
    		select @msg = 'Missing Zip Code!', @rcode = 1
    		goto bspexit
    		end
    	end*/
    
    Update bAPTH set AddressSeq=@addrseq, PayOverrideYN=@addrovryn, PayName=@name,PayAddress=@addr,
    		 PayCity=@city, PayState=@state, PayZip=@zip, PayCountry=@country, PayAddInfo=@addlinfo
    		 where APCo=@co and Mth=@mth and APTrans=@trans 
	if @@rowcount = 0 
		begin
			select @msg = 'bAPTH was not updated with Address Override info.', @rcode = 1
			goto bspexit
		end
    
       bspexit:
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPPayAddrUpdate] TO [public]
GO
