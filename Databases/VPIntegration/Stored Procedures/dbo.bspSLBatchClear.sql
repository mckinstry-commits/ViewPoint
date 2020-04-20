SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspSLBatchClear    Script Date: 8/28/99 9:33:40 AM ******/
   CREATE    procedure [dbo].[bspSLBatchClear]
   /*************************************************************************************************
    * CREATED BY: kf 12/10/97
    * MODIFIED By : kf 12/10/97
	*				JG 10/4/10 - Remove records from SLInExclusionsBatch
	*               DW 07/13/12 - TK-16355 - Modified the 'BatchClear' stored procedures to delete from the batch tables instead of the batch views.
    *
    * USAGE:
    * Clears batch tables
    *
    * INPUT PARAMETERS
    *   SLCo        SLCo
    *   Month       Month of batch
    *   BatchId     Batch ID to validate
    * OUTPUT PARAMETERS
    *   @errmsg     if something went wrong
    * RETURN VALUE
    *   0   success
    *   1   fail
    **************************************************************************************************/
   
   	(@co bCompany, @mth bMonth, @batchid bBatchID, @errmsg varchar(60) output)
   as
   set nocount on
   declare @rcode int, @source bSource, @tablename char(20), @status tinyint
   
   select @rcode = 0
   
   select @tablename=TableName, @status = Status
   from HQBC where Co=@co and Mth=@mth and BatchId=@batchid
   
   if @status = 4
       begin
       select @errmsg = 'Batch status is Posting in Progress, cannot be cleared.', @rcode = 1
       goto bspexit
       end
   
   if @tablename='SLCB'
   	begin
   	delete from bSLCA where SLCo=@co and Mth=@mth and BatchId=@batchid
   	delete from bSLCB where Co=@co and Mth=@mth and BatchId=@batchid
   	end
   
   if @tablename='SLXB'
   	begin
   	delete from bSLXA where SLCo=@co and Mth=@mth and BatchId=@batchid
   	delete from bSLXB where Co=@co and Mth=@mth and BatchId=@batchid
   	end
   
   if @tablename='SLHB'
   	begin
   	delete from bSLIA where SLCo=@co and Mth=@mth and BatchId=@batchid
   	delete from bSLIB where Co=@co and Mth=@mth and BatchId=@batchid
   	delete from bSLHB where Co=@co and Mth=@mth and BatchId=@batchid
   	DELETE FROM vSLInExclusionsBatch
   	WHERE Co=@co and Mth=@mth and BatchId=@batchid
   	end
   
   update bHQBC set Status=6 where Co=@co and Mth=@mth and BatchId=@batchid
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspSLBatchClear] TO [public]
GO
