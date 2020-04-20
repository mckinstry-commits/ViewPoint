SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPHBCMRefVal    Script Date: 8/28/99 9:33:59 AM ******/
   CREATE    proc [dbo].[bspAPHBCMRefVal]
   /***********************************************************
    * CREATED BY	: SE 10/2/97
    * MODIFIED BY	: SE 10/2/97
    *              kb 10/28/2 - issue #18878 - fix double quotes
    *		ES 03/11/04 - Issue #23061 - isnull wrap
    *
    * USAGE:
    * validates AP Reference to see if it is unique.  Checks APHB and APTH 
    *
    * INPUT PARAMETERS
    *   APCo      AP Co to validate against 
    *   Mth       Month of batch
    *   BatchId   BatchID, to make sure we don't check the Ref on
    *   Seq       the current line 
    *   CMCo      CMCompany to check in
    *   CMAcct    CMAccount to check in 
    *   CMRef     Reference to Validate
    * 
    * OUTPUT PARAMETERS
    *   @msg      message if Reference is not unique otherwise nothing
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure  'if Fails Address, City, State and Zip are ''
    *****************************************************/ 
   
       (@apco bCompany = 0,@mth bMonth, @batchid bBatchID, @seq int, 
        @cmco bCompany, @cmacct bCMAcct, @cmref int, @msg varchar(80) output )
   as
   
   set nocount on
   
   declare @rcode int
   select @rcode = 0, @msg = 'AP Unique'
    
   select @rcode=1, @msg='Reference ' + isnull(convert(varchar(10),@cmref), '') + ' already in cash management.'  --#23061
     from bCMDT where CMCo=@cmco and CMAcct=@cmacct and convert(integer,CMRef)=@cmref and CMTransType=1

GO
GRANT EXECUTE ON  [dbo].[bspAPHBCMRefVal] TO [public]
GO
