SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     PROCEDURE [dbo].[bspAPWHUpdatePayYN]
   /***********************************************************
   * CREATED BY: MV 1/07/02
   * MODIFIED BY: GG 09/20/02 - #18522 ANSI nulls
   *				MV 07/12/04 - #25076 - @userid should have datatype bVPUserName
   *				MV 04/24/07 - #122337 - don't update PayYN to Y if out-of-compl and
   *										APCO flags = 'Y' (don't allow in a paymt batch
   *										if out-of-compl)
   *				
   * USAGE:
   * Called by the AP Payment Control form (frmAPPAYWorkfile) to update
   * th PayYN field in workfile detail records.
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
    (@co bCompany,@userid bVPUserName, @mth bDate, @trans int, @payyn bYN,
   	 @msg varchar(255) output)
      as
   
      set nocount on
   
      declare @rcode int, @errmsg varchar (100), @DontAllowPaySL bYN,
		 @DontAllowPayPO bYN,@DontAllowPayAllinv bYN
   
      select @rcode = 0
   
      if @co is null	 -- #18522
        begin
        select @errmsg = 'Missing APCompany!', @rcode = 1
        goto bspexit
        end
   
       if @mth is null	 -- #18522
        begin
        select @errmsg = 'Missing Month!', @rcode = 1
        goto bspexit
        end
   
        if @trans is null	 -- #18522
        begin
        select @errmsg = 'Missing APTrans!', @rcode = 1
        goto bspexit
        end
   
	-- get APCO flags
		 select @DontAllowPaySL = SLAllowPayYN,@DontAllowPayPO = POAllowPayYN,
		 @DontAllowPayAllinv = AllAllowPayYN from APCO where APCo=@co                 

   if @payyn='Y'
    BEGIN
    	update APWD set PayYN = 'Y' from APWD d join APTL l on
		d.APCo=l.APCo and d.Mth=l.Mth and d.APTrans=l.APTrans and d.APLine=l.APLine 
		where d.APCo=@co and d.Mth=@mth and	d.UserId=@userid and d.APTrans=@trans
		 and d.PayYN='N' and d.HoldYN='N' and (d.CompliedYN='Y' or 
			((d.CompliedYN = 'N' and l.LineType <> 6 and l.LineType <> 7 and @DontAllowPayAllinv = 'N') or
     		 (d.CompliedYN = 'N' and l.LineType = 6 and @DontAllowPayPO = 'N') or
    		 (d.CompliedYN = 'N' and l.LineType = 7 and @DontAllowPaySL = 'N')))
--		if @@rowcount=0 
--		begin
--			select @rcode=7
--		end
    END
   
   if @payyn='N'
    BEGIN
   	update APWD set PayYN = 'N' where APCo=@co and Mth=@mth and
   	UserId=@userid and APTrans=@trans and PayYN='Y'
    END
   
      bspexit:
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPWHUpdatePayYN] TO [public]
GO
