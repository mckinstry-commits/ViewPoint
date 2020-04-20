SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQBCExitCheck    Script Date: 8/28/99 9:34:47 AM ******/
    CREATE               procedure [dbo].[bspHQBCExitCheck]
    /**********************************************************************
     * Created : ??
     * Modified: GG 03/09/98
     *	JM 10-02-02 - Ref Issue 17743 Rej 1 - Needed to add a special branch for EMAdj source so this procedure
     *		will unlock EMAlloc and EMDepr batches as well as EMAdj batches since those batches are created by
     *		processing forms and validated/posted by EMCostAdj form which had assumed all batches to be EMAdj.
     *	MV 01/27/03 - #17343 - clear AP Transaction distribution files when Batch Clear is not used.
     *	TJL 03/26/03 - Issue #20639, Orphaned records left in Distribution tables by ARCashReceipts
     *				RM 02/13/04 = #23061, Add isnulls to all concatenated strings
     *				DANF 11/02/2004 - 25975 Stored Procedure cleanup
     *			TV 06/23/05 29046 - causes issues in Fuel Posting
	 *			EN 3/17/2010 #137429 resolved security glitch of using dynamic SQL with views
     * 
     * Updates the Status and InUseBy info on an existing Batch (bHQBC)
     * when exiting a posting or processing program.
     *
     * Resets Status to 'open'(0) if current Status is less than
     * 'posting in progress'(4), or 'posted'(5).  Resets Status
     * to 'cancelled'(6) if Batch Table is empty.
     *
     * Resets InUseBy to null if Status <> 5 (posted).
     *
     * Pass in:
     *	@co          Company
     *	@mth         Month
     *	@batchid     BatchId
     *	@source      Source
     *	@tablename   Batch Table Name
     *
     * Returns:
     *	0 = success
     *	1 = failed, with error message
     *********************************************************************/
    
    	@co bCompany, @mth bMonth, @batchid bBatchID, @source bSource,
    	@tablename varchar(20), @errmsg varchar(255) output
    
    as
    set nocount on
    declare 	@inuseby bVPUserName, @status tinyint, @tsql varchar(255), @rcode int,
    		@sql nvarchar(300), @paramsin nvarchar(300), @c int
    
    select @rcode = 0, @status = 0 	/* set Status to 0 (open), reset to 6 (cancelled) if empty batch */
    
    /* check HQ Batch Control - must match Co#, Mth, BatchId, Source, and TableName */
    if @source = 'EMAdj'
    	select @status = Status from bHQBC with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid 
    		and (Source = 'EMAdj' or Source = 'EMAlloc' or Source = 'EMDepr')
    		 and TableName = @tablename and InUseBy = SUSER_SNAME()
    else
    	select @status = Status from bHQBC  with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid 
    		and Source = @source and TableName = @tablename and InUseBy = SUSER_SNAME()
   
    if @@rowcount = 0
    	begin
    	select @errmsg = 'Invalid Batch!'--, @rcode = 1  TV 06/23/05 29046 - causes issues in Fuel Posting
   
   	/*+
            ' @status=' + convert(varchar(12),@status) +
            ' @co=' + convert(varchar(3),@co) +
            ' @mth=' + convert(varchar(12),@mth) +
            ' @batchid=' + convert(varchar(3),@batchid) +
            ' @source=' + @source +
            ' @tablename=' + @tablename +
            ' SUSER_SNAME()=' + SUSER_SNAME(), @rcode = 1
    	goto bspexit
    	end
    else
        begin
        select @errmsg = 'Batch OK-' +
            ' @status=' + convert(varchar(12),@status) +
            ' @co=' + convert(varchar(3),@co) +
            ' @mth=' + convert(varchar(12),@mth) +
            ' @batchid=' + convert(varchar(3),@batchid) +
            ' @source=' + @source +
            ' @tablename=' + @tablename +
            ' SUSER_SNAME()=' + SUSER_SNAME(), @rcode = 1*/
   
       goto bspexit
       end
    
    if @status < 4	/* leave status 4 (posting in progress) and 5 (updated) unchanged */
    begin
    	select @status = 0		/* default status - open */
    	/* check for empty batch table */
    	--select @tsql = 'select Co from ' + isnull(@tablename,'') + ' where Co = ' + isnull(convert(varchar(3),@co),'')
    	--select @tsql = isnull(@tsql,'')  + ' and Mth = ''' + isnull(convert(varchar(8),@mth,1),'') + ''' and BatchId = ' + isnull(convert(varchar(10),@batchid),'')
    	--execute (@tsql)

--#137429 replaced in-code sp_executesql with vspHQBCTableRowCount to do the same thing but using with execute as 'viewpointcs' 
--			to expand the scope thus avoiding false @c=0 due to security 
   
--    	select @sql = 'select @c=COUNT(*)  from ' + isnull(@tablename,'') + ' with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid'
--    	set @paramsin = N'@co tinyint, @mth bMonth, @batchid int, @tablename varchar(20), @c int output '
--    	EXECUTE sp_executesql @sql, @paramsin, @co, @mth, @batchid, @tablename, @c output

		EXEC @rcode = vspHQBCTableRowCount @co, @mth, @batchid, @tablename, @c output, @errmsg output
    
    	if isnull(@c,0) = 0
            	begin
    	    select @status = 6	/* empty batch - set Status to 6(cancelled) and clear out HQCC */
    	    delete from bHQCC where Co=@co and Mth=@mth and BatchId=@batchid
    
    	    /* Clean up distribution files based on source */
    	    /* Needed in case user doesn't use batch again */
    	    if @source in ('AR Invoice', 'ARFinanceC', 'ARRelease', 'AR Receipt','SM Invoice')
              	    	begin
    		 delete from bARBI where ARCo = @co and Mth = @mth and BatchId = @batchid
    		 delete from bARBM where   Co = @co and Mth = @mth and BatchId = @batchid
    		 delete from bARBA where   Co = @co and Mth = @mth and BatchId = @batchid
    	       	 end
    	     If  @source = 'AP Entry'	
    		begin
    		/* clear HQ Batch Errors */
    		delete bHQBE where Co = @co and Mth = @mth and BatchId = @batchid
    		/* clear EM Distributions Audit */
    		delete bAPEM where APCo = @co and Mth = @mth and BatchId = @batchid
    		/* clear GL Distributions Audit */
    		delete bAPGL where APCo = @co and Mth = @mth and BatchId = @batchid
    		/* clear Inventory Distributions Audit */
    		delete bAPIN where APCo = @co and Mth = @mth and BatchId = @batchid
    		/* clear Job Cost Distributions Audit */
    		delete bAPJC where APCo = @co and Mth = @mth and BatchId = @batchid
    		/*clear HQCC entries */
    		delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid
    		/* clear PO JC Distribution Audit */
    		delete bPORJ where POCo = @co and Mth = @mth and BatchId = @batchid
    		/* clear PO GL Distribution Audit */
    		delete bPORG where POCo = @co and Mth = @mth and BatchId = @batchid
    		/* clear PO EM Distribution Audit */
    		delete bPORE where POCo = @co and Mth = @mth and BatchId = @batchid
    		/* clear PO IN Distribution Audit */
    		delete bPORN where POCo = @co and Mth = @mth and BatchId = @batchid
    		end
            	end
    end
    
    /* InUseBy reset to null unless batch status is 'posted' */
    select @inuseby = null
    if @status = 5 select @inuseby = SUSER_SNAME() 
   update bHQBC
   	set InUseBy = @inuseby, Status = @status
   	where Co = @co and Mth = @mth and BatchId = @batchid
   
   
   
    
   
   
    if @@rowcount = 0
    	begin
    	select @errmsg = 'Unable to update HQ Batch Control info!', @rcode = 1
    	end
    
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQBCExitCheck] TO [public]
GO
