SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspHQBEInsert]
   /*************************************************************
   *	Adds entries to HQ Batch Error table - called from
   *	batch validation procedures.
   *
   *	pass in Co, Mth, BatchId, and ErrorText
   *	gets next available Seq#, and inserts bHQBE entry
   *
   * 	returns 0 if successfull, 1 and error msg if not
   **************************************************************/
   
   	(@co bCompany, @mth bMonth, @batchid bBatchID, @errortext varchar(255),
   	 @errmsg varchar(60) output)
   as
   	set nocount on
   	declare @rcode int, @seq int
   	select @rcode=0, @seq = 0
   
   /* get next Seq# for HQ Batch Error entry */
   select @seq = isnull(max(Seq),0)+1 from bHQBE where Co = @co and Mth = @mth and BatchId = @batchid
   
   /* add HQ Batch Error entry */
   insert bHQBE (Co, Mth, BatchId, Seq, ErrorText)
   values (@co,@mth,@batchid,@seq,@errortext)
   if @@rowcount = 0
   	select @errmsg = 'Unable to add HQ Batch Error entry!', @rcode = 1
   else
   	select @errmsg = ''
   	
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQBEInsert] TO [public]
GO
