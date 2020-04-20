SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPClearPost    Script Date: 8/28/99 9:33:57 AM ******/
   CREATE proc [dbo].[bspAPClearPost]
   
   /****************************************************************************
    * CREATED BY: kf 10/10/97
    * MODIFIED By : 04/22/99 GG    (SQL 7.0)
    *		SR 09/27/01 - Issue 14734 , update header APTH OpenYN to 'N'
    *              kb 1/15/2 - issue #15848
    *		MV 10/31/02 - 18878 quoted identifier cleanup.
    *
    * USAGE:
    * Used by APClear program clears transactions from the APCT (Clear batch) file
    * an error is returned if any goes wrong.
    *
    *  INPUT PARAMETERS
    *   @co= Company
    *   @mth= Month to insert batch record for
    *   @batchid= BatchId to insert batch record for
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs
    * RETURN VALUE
    *   0         success
    *   1         Failure
    ****************************************************************************/
   (@co bCompany,@mth bMonth,@batchid bBatchID, @dateposted bDate, @msg varchar(100) output)
   as
   
   set nocount on
   
   declare @rcode int, @keyglco bCompany, @keyglacct bGLAcct, @checkremain bDollar,
   	@source bSource, @status tinyint
   
    /* check for date posted */
     if @dateposted is null
        begin
         select @msg = 'Missing posting date!', @rcode = 1
         goto bspexit
        end
   
   /* validate HQ Batch */
     select @source = 'AP Clear'
   
     exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, 'APCT', @msg output,
   
     	@status output
     if @rcode <> 0 goto bspexit
   
     if @status <> 3 and @status <> 4	/* valid - OK to post, or posting in progress */
        begin
         select @msg = 'Invalid Batch status -  must be ''valid - OK to post'' or ''posting in progress''!', @rcode = 1
         goto bspexit
        end
   
   
   /* set HQ Batch status to 4 (posting in progress) */
     update bHQBC
     	set Status = 4, DatePosted = @dateposted
     	where Co = @co and Mth = @mth and BatchId = @batchid
     if @@rowcount = 0
        begin
         select @msg = 'Unable to update HQ Batch Control information!', @rcode = 1
         goto bspexit
        end
   
   
   update APTD set Status=4, PaidMth=@mth, PaidDate=@dateposted
   from APCT a, APTD b
   where b.APCo=a.Co and b.Mth=a.ExpMth and b.APTrans=a.APTrans
   	and b.Status<3 and a.Co=@co and a.BatchId=@batchid and a.Mth=@mth
   
   update bAPTH  Set OpenYN='N'
   from bAPCT a, bAPTH b
   where b.APCo=a.Co and b.Mth=a.ExpMth and b.APTrans=a.APTrans
   	and a.Co=@co and a.BatchId=@batchid and a.Mth=@mth
   
   delete from APCD where APCD.Co=@co and APCD.BatchId=@batchid and APCD.Mth=@mth
   
   delete from APCT where APCT.Co=@co and APCT.BatchId=@batchid and APCT.Mth=@mth
   
   /* delete HQ Close Control entries */
   delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid
   
   /* set HQ Batch status to 5 (posted) */
   update bHQBC
   	set Status = 5, DateClosed = getdate()
   	where Co = @co and Mth = @mth and BatchId = @batchid
   	if @@rowcount = 0
   		begin
   		select @msg = 'Unable to update HQ Batch Control information!', @rcode = 1
   		goto bspexit
   		end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPClearPost] TO [public]
GO
