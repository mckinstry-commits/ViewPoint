SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspCMDBTotals    Script Date: 8/28/99 9:34:16 AM ******/
   CREATE  procedure [dbo].[bspCMDBTotals]
   /***********************************************************
    * CREATED BY: SE   8/20/96
    * MODIFIED By : SE 8/20/96
    *               LM 3/30/99 changed sum(isnull(... to isnull(sum...
    *
    * USAGE:
    * Provides Totals for Adjustments, Checks and Deposits.   
    *  used in CM outstnading entries     
    * 
    * INPUT PARAMETERS
    *   CMCo        CM Co 
    *   Month       Month of batch
    *   BatchId     Batch ID to validate                
    * OUTPUT PARAMETERS
    *   @errmsg     if something went wrong
    * RETURN VALUE
    * returns Adjustments, Checks and Depostis totals as a recordset
    *****************************************************/ 
   
   	@co bCompany, @mth bMonth, @batchid bBatchID,
   	@errmsg varchar(255) output
   
   as
   
   set nocount on
   
   declare @adjtotal bDollar, @chktotal bDollar, @deptotal bDollar, @rcode int
   
   select @rcode = 0
   
   if not exists(select * from bCMDB where Co = @co and Mth = @mth and BatchId = @batchid)
   	begin
   	select @errmsg = 'No detail entries for this batch!', @rcode = 1
   	goto bspexit
   	end
   
   /* get totals from CM Detail Batch table */
   select @adjtotal = isnull(sum(isnull(Amount,0)),0)
   	from bCMDB
   	where Co = @co and Mth = @mth and BatchId = @batchid and CMTransType = 0
   
   select @chktotal = isnull(sum(isnull(Amount,0)),0)
   	from bCMDB
   	where Co = @co and Mth = @mth and BatchId = @batchid and CMTransType = 1
   
   select @deptotal = isnull(sum(isnull(Amount,0)),0)
   	from bCMDB
   	where Co = @co and Mth = @mth and BatchId = @batchid and CMTransType = 2
   
   select 'AdjTotal'=isnull(@adjtotal,0), 'ChkTotal'=(-1*isnull(@chktotal,0)), 'DepTotal' =isnull(@deptotal,0)
    
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspCMDBTotals] TO [public]
GO
