SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspMSInvoiceUnique]
   /***********************************************************
    * Created By:  GF 11/15/2000
    * Modified By:
    *
    * USAGE:
    * validates MS invoice to insure that it is unique.
    * Checks MSIH and MSIB
    *
    * INPUT PARAMETERS
    * MSCo, Mth, BatchId, BatchSeq, MSInv
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   (@msco bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @seq bTrans = null,
    @msinv varchar(10) = null, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @msco is null
       begin
       select @msg = 'Missing MS Company!', @rcode = 1
       goto bspexit
       end
   
   if @mth is null
       begin
       select @msg = 'Missing Batch Month!', @rcode = 1
       goto bspexit
       end
   
   if @batchid is null
       begin
       select @msg = 'Missing Batch ID!', @rcode = 1
       goto bspexit
       end
   
   if @seq is null
       begin
       select @msg = 'Missing Batch Sequence!', @rcode = 1
       goto bspexit
       end
   
   if @msinv is null
       begin
       select @msg = 'Missing MS Invoice!', @rcode = 1
       goto bspexit
       end
   
   -- check MS
   select @rcode = 1, @msg = 'Invoice ' + convert(varchar(10),isnull(@msinv,'')) + ' already exists'
   from bMSIH where MSCo=@msco and MSInv=@msinv
   
   select @rcode=1, @msg = 'Invoice ' + convert(varchar(10),isnull(@msinv,'')) + ' is in use by batch Month:' + substring(convert(varchar(12),Mth,3),4,5) + ' ID:' + convert(varchar(10),BatchId)
   from bMSIB where Co=@msco and MSInv=@msinv and not (Mth=@mth and BatchId=@batchid and BatchSeq=@seq)
   
   
   
   bspexit:
       if @rcode <> 0 select @msg = isnull(@msg,'')
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSInvoiceUnique] TO [public]
GO
