SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspMSIBInvVal]
   /*************************************
   * Created By:   GF 11/13/2000
   * Modified By:
   *
   * validates MS Invoice to batch for print.
   *
   * Pass:
   *	MS Company, Month, BatchId, MS Invoice
   *
   * Success returns:
   *	0 and Description from bMSIB
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@msco bCompany = null, @mth bMonth = null, @batchid bBatchID, @msinv varchar(10) = null,
    @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @msco is null
   	begin
   	select @msg = 'Missing MS Company number', @rcode = 1
   	goto bspexit
   	end
   
   if @mth is null
       begin
       select @msg = 'Missing Batch month', @rcode = 1
       goto bspexit
       end
   
   if @batchid is null
       begin
       select @msg = 'Missing Batch ID', @rcode = 1
       goto bspexit
       end
   
   if @msinv is null
   	begin
   	select @msg = 'Missing MS Invoice number', @rcode = 1
   	goto bspexit
   	end
   
   -- validate invoice in MSIB
   select @msg=Description
   from bMSIB with (nolock) where Co=@msco and Mth=@mth and BatchId=@batchid and MSInv=@msinv
   if @@rowcount = 0
       begin
       select @msg = 'Not a valid MS Invoice', @rcode = 1
       goto bspexit
       end
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSIBInvVal] TO [public]
GO
