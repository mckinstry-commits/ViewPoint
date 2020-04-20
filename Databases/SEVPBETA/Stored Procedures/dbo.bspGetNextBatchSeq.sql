SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGetNextBatchSeq    Script Date: 8/28/99 9:34:47 AM ******/
CREATE procedure [dbo].[bspGetNextBatchSeq] 
/**********************************************************************
* Created By:
* Modified By:	GF 06/18/2008 - issue #       - need to execute as 'viewpointcs' for V6.
*
*
* Provides next available Batch Sequence # from the batch table
* assoicated with a given bHQBC entry.
*
* Used by posting programs when adding a 'new' entry.
* 
* pass in Company, Month, and BatchId
*
**********************************************************************/
(@co bCompany, @mth bMonth, @batchid bBatchID)

with execute as 'viewpointcs'
as
set nocount on

declare @tablename varchar(20), @tsql varchar(255)

/* get batch table name from HQ Batch Control */
select @tablename = TableName from bHQBC
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 1
	begin
	/* get next available Batch Seq # */
	select @tsql = 'select Seq = isnull(max(BatchSeq),0)+1 from ' + @tablename
			+ ' where Co = ' + convert(char(3),@co) + ' and Mth = '''
			+ convert(varchar(8),@mth,1) + ''' and BatchId = ' + convert(varchar(10),@batchid)

	execute (@tsql)
	end

GO
GRANT EXECUTE ON  [dbo].[bspGetNextBatchSeq] TO [public]
GO
