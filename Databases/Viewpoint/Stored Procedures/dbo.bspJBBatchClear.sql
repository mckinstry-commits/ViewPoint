SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspJBBatchClear]
     /*************************************************************************************************
      * CREATED BY: bc 10/28/99
      * MODIFIED By :
	  *                DW 07/13/12 - TK-16355 - Modified the 'BatchClear' stored procedures to delete from the batch tables instead of the batch views.
      *
      * USAGE:
      * Clears batch tables
      *
      * INPUT PARAMETERS
      *   JBCo        JB Co
      *   Month       Month of batch
      *   BatchId     Batch ID to validate
      *
      * OUTPUT PARAMETERS
      *   @errmsg     if something went wrong
      *
      * RETURN VALUE
      *   0   success
      *   1   fail
      **************************************************************************************************/
   
     (@co bCompany, @mth bMonth, @batchid bBatchID, @errmsg varchar(60) output)
   
     as
     set nocount on
   
     declare @rcode int, @source bSource, @tablename char(20), @status tinyint, @inuseby bVPUserName, @billnumber varchar(20)
   
     select @rcode = 0
   
     select @status=Status, @inuseby=InUseBy, @tablename=TableName
     from bHQBC
     where Co=@co and Mth=@mth and BatchId=@batchid
   
     if @@rowcount=0
     	begin
     	select @errmsg='Invalid batch.', @rcode=1
     	goto bspexit
     	end
   
     if @status=5
     	begin
     	select @errmsg='Cannot clear, batch has already been posted!', @rcode=1
     	goto bspexit
     	end
   if @status=4
    	begin
    	select @errmsg='Batch posting was interrupted, cannot clear!', @rcode=1
    	goto bspexit
    	end
     if @inuseby<>SUSER_SNAME()
     	begin
     	select @errmsg='Batch is already in use by @inuseby ' + isnull(@inuseby,'') + '!', @rcode=1
     	goto bspexit
     	end
   
   
     if @tablename='JBAR'
     	begin
        /* clear the 'in use' fields in JBIN in JBAR delete trigger */
     	delete from bJBBM where JBCo=@co and Mth=@mth and BatchId=@batchid
     	delete from bJBJC where JBCo=@co and Mth=@mth and BatchId=@batchid
     	delete from bJBGL where JBCo=@co and Mth=@mth and BatchId=@batchid
     	delete from bJBAL where Co=@co and Mth=@mth and BatchId=@batchid
     	delete from bJBAR where Co=@co and Mth=@mth and BatchId=@batchid
     	end
   
   
     update bHQBC set Status=6 where Co=@co and Mth=@mth and BatchId=@batchid
   
     bspexit:
   
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBBatchClear] TO [public]
GO
