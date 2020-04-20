SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[bspAPPayTypeGet]
    /****************************************
    * 
    *	Created: 3/3/4 - MV - #18769 - Pay Category
    *	Modified:  ES 03/11/04 - #23061 isnull wrapping 
    *				MV 03/29/04 - #18769 - design change
	*				MV 02/27/07 - #27765 - use vDDUP for 6X
    *				ECV 05/25/11 - TK-05443 - Add SM Pay Type output parameter
    *
    *	Gets Pay Types and GL Accts from bAPCO or bAPPC
    *	depending on whether the user is using Pay Category 
    *	(multi-divisional accounting) or not.   
    *
    *	inputs: Company, UserId, 
    *
    *	outputs: ExpPayType,JobPayType,SubPayType,RetPayType
    *				DiscTakenGLAcct, DiscOfferGLAcct,PayCategory, msg
    *
    *****************************************/
    (@co bCompany, @userid bVPUserName = null,@exppaytype tinyint output,
    	@jobpaytype tinyint output, @smpaytype tinyint output, @subpaytype tinyint output, 
    	@retpaytype tinyint output, @discoffglact bGLAcct output,
    	@disctakenglacct bGLAcct output, @paycategory int output, @msg varchar(100) output)
    as
    set nocount on
    
    /* If the user is not using Pay Category (mulitdivisional accounting) 
    	then pay types and DiscGLAccts come directly from bAPCO. If the user is using Pay Category
      	then default Pay Category (and it's associated pay types and GLAccts) in this order:
    	 	1. User Profile default Pay Category set in DDUP  
    		2. Pay Category default set in bAPCO */
    
    declare @rcode int,@apcopaycategory int,@usingpaycategory bYN
    
    select @rcode = 0
    
    --check bAPCO first
    select @exppaytype=ExpPayType, @jobpaytype=JobPayType,@subpaytype=SubPayType, @retpaytype=RetPayType,
    	@discoffglact=DiscOffGLAcct, @disctakenglacct=DiscTakenGLAcct, @usingpaycategory=PayCategoryYN,
    	@apcopaycategory=PayCategory, @smpaytype=SMPayType
    	from bAPCO WITH (NOLOCK) where APCo = @co
    	if @@rowcount=0
    	begin
    		select @msg = 'AP Company not set up. ', @rcode = 1
    		goto bspexit
    	end
    -- get paytypes and glaccts from bAPPC if using pay category
    if @usingpaycategory='Y'
    	begin
    		--User Profile default Pay Category
    		if @userid is not null
    		begin
    		select @paycategory = PayCategory from vDDUP WITH (NOLOCK)
    			 where rtrim(ltrim(VPUserName))=rtrim(ltrim(@userid))
    			 if isnull(@paycategory,0)> 0
    				begin
    				select @exppaytype=ExpPayType, @jobpaytype=JobPayType,@subpaytype=SubPayType, @retpaytype=RetPayType,
    					@discoffglact=DiscOffGLAcct, @disctakenglacct=DiscTakenGLAcct, @smpaytype=SMPayType 
    					from bAPPC WITH (NOLOCK)
    					where APCo=@co and PayCategory=@paycategory 
    				if @@rowcount = 0
    					begin
    					select @msg = 'Pay Category: ' + 
    						isnull(convert(varchar(10),@paycategory), '') + ' is invalid for APCo: ' + convert(varchar(3),@co), @rcode = 1  
    					goto bspexit
    					end
    				else
    					goto endcheck
    				end
   			else
   				begin
   				select @paycategory = null --if DDUP returns 0 paycategory clear it
   				end
    		end
    		
    		--Pay Category default in bAPCO 
    		if isnull(@apcopaycategory,0)> 0
    			begin
    			select @exppaytype=ExpPayType, @jobpaytype=JobPayType,@subpaytype=SubPayType, @retpaytype=RetPayType,
    				@discoffglact=DiscOffGLAcct, @disctakenglacct=DiscTakenGLAcct, @smpaytype=SMPayType
    				from bAPPC WITH (NOLOCK)
    				where APCo=@co and PayCategory=@apcopaycategory 
    			if @@rowcount = 0
    				begin
    				select @msg = 'Pay Category: ' + 
    						isnull(convert(varchar(10),@paycategory), '') + ' is invalid for APCo: ' + convert(varchar(3),@co), @rcode = 1  
    				goto bspexit
    				end
    			else
    				select @paycategory=@apcopaycategory
    			end
   		else
   			begin
   			select @paycategory = null --if APCO returns 0 paycategory clear it
   			end
    	end
    
    endcheck:
    
    bspexit:
    return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPPayTypeGet] TO [public]
GO
