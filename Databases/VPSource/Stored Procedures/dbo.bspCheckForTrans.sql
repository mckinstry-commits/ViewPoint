SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspCheckForTrans    Script Date: 8/28/99 9:32:38 AM ******/
   CREATE  procedure [dbo].[bspCheckForTrans]
   /***********************************************************
    * CREATED BY: CJW 6/16/97
    * MODIFIED By : CJW 6/16/97
    *
    * USAGE:
    * This procedure is used by the AR Finance charge program to pull validate if line exisit
    * pull approptiate contract item
    *
    * Checks batch info in bHQBC, and transaction info in bARTL.
    * Adds entry to the Item that it is in ARTL for the seq passed in
    *
    * 
    * 
   
   
    * INPUT PARAMETERS
    *   Co         JC Co to pull from
    *   Mth        Month of batch
    *   BatchId    Batch ID to insert transaction into 
    *   AR Line    ar to pull
    *   Item       Item to pull
    *   Seq        Seq to put item under
    * OUTPUT PARAMETERS
    *
   
    * RETURN VALUE
    *   0   success
    *   1   fail
    *   3   not found  if no errors but just not available
    *****************************************************/ 
   
   	@co bCompany, @ar bTrans, @line int, @contractitem bContractItem output, @errmsg varchar(200) output
   
   as
   set nocount on
   
   declare @rcode int, @inuseby bVPUserName, @status tinyint,
   	@dtsource bSource, @inusebatchid bBatchID, @inusemth bMonth, @errtext varchar(60)
   
   
   /* all ar's can be pulled into a batch as long as it's InUseFlag is set to null*/
   select @inusebatchid = InUseBatchID from ARTH where ARCo=@co and ARTrans=@ar
   if @@rowcount = 0 
   	begin
   	select @errmsg = 'The AR Transaction :' + convert(varchar(5),@ar) + ' cannot be found.' , @rcode = 1
   	select @rcode = 3
   	goto bspexit
   	end
   
   /*Now make sure the Item is not flaged */
   select @contractitem = ARTL.Item from ARTL where ARCo=@co and ARTrans=@ar and ARLine = @line
   if @@rowcount = 0 
   	begin
   	select @errmsg = 'The AR Line :' + convert(varchar(5),@line) + ' cannot be found.' , @rcode = 3
   	goto bspexit
   	end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspCheckForTrans] TO [public]
GO
