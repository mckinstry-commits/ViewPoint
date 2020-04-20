SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE          procedure [dbo].[bspPORSBatchCheck]
   /***********************************************************
    * CREATED BY: DANF 06/19/02
    * MODIFIED By : 
    *
    * USAGE:
    * This procedure will check for any open other PO Initialization batches.
    * There can be only one PO Initialization batch being processed per company.
    *
    * INPUT PARAMETERS
    *   POCo	PO Co to Validate
    *   Mth        Month of batch
    *   BatchId    Batch ID 
    * OUTPUT PARAMETERS
    *   Error Messages
    *
    * RETURN VALUE
    *   0   success
    *   1   fail
    *****************************************************/
   
   	@co bCompany, @mth bMonth, @batchid bBatchID,
       @errmsg varchar(200) output
   
   as
   
   
   set nocount on
   
   declare @rcode int, @porsco bCompany, @porsmth bMonth, 
           @porsbatchid bBatchID, @porscreatedby bVPUserName
   
   select @rcode = 0
   
   
   select @porsco = Co, @porsmth = Mth,  @porsbatchid = BatchId, @porscreatedby = CreatedBy from bHQBC
   where (Co = @co and Source ='PO InitRec' and Status <5)
   and not ( Co = @co and Mth = @mth and BatchId = @batchid and Source = 'PO InitRec')
   if @@rowcount>0 select @rcode = 1, @errmsg = 'Another PO Initialization Batch already exists. ' + char(13) + char(10) + 'Check Month ' + convert(varchar(20),@porsmth,101) + ', Batch ' + convert(varchar(6),@porsbatchid) + ', User ' + @porscreatedby
   
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPORSBatchCheck] TO [public]
GO
