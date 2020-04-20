SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      PROCEDURE [dbo].[vspAPWDCheck]
   /***********************************************************
   * CREATED BY: MV 04/12/07
   * MODIFIED BY: 
   *
   * USAGE:
   * Called by frmAPPAYWorkfile when header PayYN checkbox is 
   * checked to check detail compliance
   *
   * INPUT PARAMETERS
   *  @co                 AP Company
   *  @mth		   Month
   *  @trans		   APTrans
   * OUTPUT PARAMETERS
   *  @msg                error message if error occurs
   *
   * RETURN VALUE
   *  0                   success
   *  1                   failure
   ************************************************************/
    (@co bCompany,@userid bVPUserName, @mth bDate, @trans int,@msg varchar(255) output)
      as
   
      set nocount on
   
      declare @rcode int, @DontAllowPaySL bYN,
		 @DontAllowPayPO bYN,@DontAllowPayAllinv bYN
   
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
           
		select 1 from APWD where APCo=@co and Mth=@mth and UserId=@userid and APTrans=@trans
		if @@rowcount = 0 goto bspexit 
		
		-- check on hold
		if not exists(select 1 from APWD where APCo=@co and Mth=@mth and
		UserId=@userid and APTrans=@trans and HoldYN='N')
		begin
		select @msg='On hold.', @rcode=1
		goto bspexit
		end 
 
		-- check compliance        
		-- get APCO flags
		 select @DontAllowPaySL = SLAllowPayYN,@DontAllowPayPO = POAllowPayYN,
		 @DontAllowPayAllinv = AllAllowPayYN from APCO where APCo=@co    

		if not exists(select 1 from APWD d join APTL l on
		d.APCo=l.APCo and d.Mth=l.Mth and d.APTrans=l.APTrans and d.APLine=l.APLine 
		where d.APCo=@co and d.Mth=@mth and	d.UserId=@userid and d.APTrans=@trans
		 and d.HoldYN='N' and (CompliedYN='Y' or 
			((d.CompliedYN = 'N' and l.LineType <> 6 and l.LineType <> 7 and @DontAllowPayAllinv = 'N') or
     		 (d.CompliedYN = 'N' and l.LineType = 6 and @DontAllowPayPO = 'N') or
    		 (d.CompliedYN = 'N' and l.LineType = 7 and @DontAllowPaySL = 'N'))))
			begin
			select @msg='Out of compliance.', @rcode=1
			end
		else
			begin
			select @rcode=0
			end

      bspexit:
       return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspAPWDCheck] TO [public]
GO
