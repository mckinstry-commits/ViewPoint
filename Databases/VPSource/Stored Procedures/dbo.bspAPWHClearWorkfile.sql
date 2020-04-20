SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROCEDURE [dbo].[bspAPWHClearWorkfile]
    /***********************************************************
    * CREATED BY: MV 12/10/01
    * MODIFIED BY: kb 8/1/2 - issue #18147
    *				GG 09/20/02 - #18522 ANSI nulls
    *				MV 07/12/04 - #25076 - @userid should have datatype bVPUserName
	*				MV 12/04/08 - #131323 - clear workfile only in current company
    * USAGE:
    * Called by the AP Payment Control form (frmAPPAYWorkfile) to clear the 
    * paypment workfile for the user.
    *
    * INPUT PARAMETERS
    *  @co                 AP Company
    *  @userid             The user's system login
    * OUTPUT PARAMETERS
    *  @msg                error message if error occurs
    *
    * RETURN VALUE
    *  0                   success
    *  1                   failure
    ************************************************************/
     (@co bCompany, @userid bVPUserName, @updatediscounts bYN, 
       @msg varchar(255) output)
       as
    
       set nocount on
    
       declare @rcode int, @errmsg varchar (100),@expmth bMonth, @aptrans bTrans
    
       select @rcode = 0
    
       if @co is null	-- #18522
         begin
         select @errmsg = 'Missing APCompany!', @rcode = 1
         goto bspexit
         end
    
        if @userid is null	 -- #18522
         begin
         select @errmsg = 'Missing User login!', @rcode = 1
         goto bspexit
         end
    
    	if @updatediscounts = 'Y'
    		begin
    		select @expmth = min(Mth) from bAPWH where APCo = @co 
    		  and UserId = @userid and DiscCancelDate is not null
    		while @expmth is not null
    			begin
    			select @aptrans = min(APTrans) from bAPWH where APCo = @co
    			  and UserId = @userid and Mth = @expmth 
    			  and DiscCancelDate is not null
    			while @aptrans is not null
    				begin
    				update bAPTD set DiscTaken = w.DiscTaken from bAPWD w 
    				  join bAPTD t on t.APCo = w.APCo and t.Mth = w.Mth 
    				  and t.APTrans = w.APTrans and t.APLine = w.APLine 
    				  and t.APSeq = w.APSeq where t.APCo = @co and t.Mth = @expmth
    				  and t.APTrans = @aptrans
    			  
    				select @aptrans = min(APTrans) from bAPWH where APCo = @co
    				  and UserId = @userid and Mth = @expmth 
    				  and DiscCancelDate is not null and APTrans > @aptrans
    				
    				end
    			select @expmth = min(Mth) from bAPWH where APCo = @co 
    			  and UserId = @userid  
    			   and DiscCancelDate is not null and Mth > @expmth
    			end
    		end		
        Delete from APWH where APCo=@co and UserId = @userid

       bspexit:
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPWHClearWorkfile] TO [public]
GO
