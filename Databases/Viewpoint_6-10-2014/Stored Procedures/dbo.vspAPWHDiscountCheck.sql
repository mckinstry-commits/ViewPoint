SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [dbo].[vspAPWHDiscountCheck]
    /***********************************************************
    * CREATED BY: MV 12/18/06
    * MODIFIED BY: 

    * USAGE:
    * Called by frmAPPAYWorkfile to check for cancelled discounts  
    * before paying or clearing the Workfile.
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
     (@co bCompany, @userid bVPUserName,@clearorpay varchar(1),@discountcheck varchar(1) output,@msg varchar(255) output)
       as
    
       set nocount on
    
       declare @rcode int, @errmsg varchar (100), @count int
    
       select @rcode = 0, @count = 0
    
       if @co is null	
         begin
         select @errmsg = 'Missing APCompany!', @rcode = 1
         goto bspexit
         end
    
        if @userid is null	 
         begin
         select @errmsg = 'Missing User login!', @rcode = 1
         goto bspexit
         end

		if @clearorpay is null or @clearorpay = ''	 
         begin
         select @errmsg = 'Missing Clear or Pay flag!', @rcode = 1
         goto bspexit
         end
		
		select @discountcheck = 'N'
		if @clearorpay = 'P'
			begin
			select @count = (select count(*) from APWD d join APWH h on h.APCo = d.APCo 
                and h.Mth = d.Mth and h.APTrans = d.APTrans
                join APTD t on t.APCo = d.APCo and t.Mth = d.Mth and t.APTrans = d.APTrans
                and t.APLine = d.APLine and t.APSeq = d.APSeq 
                Where h.DiscCancelDate Is Not Null and h.PayYN = 'N' and d.DiscTaken <> t.DiscTaken 
				and h.APCo = @co and h.UserId = @userid)
			if @count > 0 select @discountcheck='Y'
			goto bspexit
			end

		if @clearorpay = 'C'
			begin
				select @count = (select count(*) from APWD d join APWH h on h.APCo = d.APCo 
                and h.Mth = d.Mth and h.APTrans = d.APTrans
                join APTD t on t.APCo = d.APCo and t.Mth = d.Mth and t.APTrans = d.APTrans
                and t.APLine = d.APLine and t.APSeq = d.APSeq 
                Where h.DiscCancelDate Is Not Null and d.DiscTaken <> t.DiscTaken 
				and h.APCo = @co and h.UserId = @userid)
			if @count > 0 select @discountcheck='Y'
			end

       bspexit:
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPWHDiscountCheck] TO [public]
GO
