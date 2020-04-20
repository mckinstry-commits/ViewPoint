SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspINMOPurge    Script Date: 12/19/2003 7:57:51 AM ******/
   
   
   
   CREATE    procedure [dbo].[bspINMOPurge]
   /************************************************************************
    * Created: GG 04/17/02
    * Modified:  DC 12/19/03 23061 - Check for ISNull when concatenating fields to create descriptions
    *
    * Called by the IN MO Purge program to delete a Material Order and all of its
    * Items.  Status must be 'closed', and Month Closed must be
    * equal to or earlier than the Last Month Closed in SubLedgers.
    *
    * Input parameters:
    *  @co         IN Company
    *  @mth        Selected month to purge MOs through
    *  @mo         Material Order to Purge
    *
    * Output parameters:
    *  @rcode      0 =  successful, 1 = failure
    *
    *************************************************************************/
   
   (@rcode int = 0 output,    @co tinyint = null, @mth smalldatetime = null, @mo varchar(20) = null, @errmsg varchar(255) output)
   
   as
   
   declare  @status tinyint, @mthclosed bMonth, @inusemth bMonth, @inusebatchid bBatchID
   
   set nocount on
   
   if @co is null
    	begin
    	select @errmsg = 'Missing IN Company!', @rcode = 1
    	goto bspexit
    	end
   if @mth is null
    	begin
    	select @errmsg = 'Missing month!', @rcode = 1
    	goto bspexit
    	end
   if @mo is null
   	begin
   	select @errmsg = 'Missing Material Order!', @rcode = 1
   	goto bspexit
   	end
   
   -- make some checks before purging
   select @status = Status, @mthclosed = MthClosed, @inusemth = InUseMth, @inusebatchid = InUseBatchId
   from dbo.INMO with(nolock) where INCo = @co and MO = @mo
   if @@rowcount = 0
       begin
       select @errmsg = 'Invalid Material Order#: ' + @mo, @rcode = 1
       goto bspexit
       end
   if @status <> 2
   	begin
   	select @errmsg = 'Material Order#: ' + @mo + ' must have a ''Closed'' status!', @rcode = 1
   	goto bspexit
   	end
   if @mthclosed > @mth
   	begin
   	select @errmsg = 'Closed in a later month!', @rcode =1
   	goto bspexit
   	end
   if @inusebatchid is not null
       begin
       select @errmsg = 'Material Order#: ' + @mo + ' is currently in use by a Batch (Mth:' + convert(varchar(8),isnull(@inusemth,'MISSING'))
           + ' Batch#: ' + convert(varchar(6),@inusebatchid) + ')', @rcode = 1
       goto bspexit
       end
   
   begin transaction
   
       -- set Purge flag to prevent HQ Auditing during delete
       update dbo.INMO set Purge = 'Y' where INCo = @co and MO = @mo
       if @@error <> 0 goto purge_error
   
   	-- delete MO Items
   	delete from dbo.INMI where INCo = @co and MO = @mo
       if @@error <> 0 goto purge_error
   
   	delete from dbo.INMO where INCo = @co and MO = @mo
       if @@error <> 0 goto purge_error
   
   commit transaction
   
   select @rcode = 0
   goto bspexit
   
   purge_error:
       rollback transaction
       select @rcode = 1
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINMOPurge] TO [public]
GO
