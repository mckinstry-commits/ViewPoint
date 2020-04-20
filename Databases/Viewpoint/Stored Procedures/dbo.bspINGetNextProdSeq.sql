SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspINGetNextProdSeq]
   /***********************************************************
    * CREATED BY	: GR 5/26/00
    * MODIFIED BY	:
    *
    * USED IN:
    *   INProduction
    *
    * USAGE:
    * gets the next production seq for the company, month, batchid and batchseq provided
    *
    * INPUT PARAMETERS
    *   @inco      IN Co to check against
    *   @mth       Batch Month
    *   @batchid   BatchId
    *   @batchseq  Batch Seq
    *
    * OUTPUT PARAMETERS
    *   @prodseq  Next production seq
    *   @msg      error message if error occurs
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   
       (@inco bCompany, @mth bMonth, @batchid int, @batchseq int, @prodseq int output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   select @prodseq = isnull(max(ProdSeq),0)+1 from bINPD
       where Co=@inco and Mth=@mth and BatchId=@batchid and BatchSeq=@batchseq
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINGetNextProdSeq] TO [public]
GO
