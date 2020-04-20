SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLBatchLock    Script Date: 8/28/99 9:34:41 AM ******/
   CREATE  procedure [dbo].[bspGLBatchLock]
   /**************************************************************
   *	MODIFIED BY:	MV 01/31/03 - #20246 dbl quote cleanup.
   *
   * Validates an existing bHQBC entry for use in a GL processing pgm 
   *
   * pass in Company, Month, and BatchId
   *
   * checks batchid, source, inuseby, status, and restriced flag
   *
   * updates inuseby to be current user and returns 0 if OK
   * returns 1 and error msg if problem
   ***************************************************************/
   
   	@co bCompany, @mth bMonth, @batchid bBatchID, @errmsg varchar(60) output
   
   as
   set nocount on
   declare @source bSource, @tablename char(20), @inuseby bVPUserName,
   	 @createdby bVPUserName, @status tinyint, @restrict bYN,
   	 @rcode int
   	
   select @rcode = 0
   
   /* validate BatchId */
   select @source = Source, @tablename = TableName, @inuseby = InUseBy,
   	@createdby = CreatedBy, @status = Status, @restrict = Rstrict
   	from bHQBC 
   	where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Invalid BatchId #!', @rcode = 1
   	goto bspexit
   	end
   
   /* check Source */
   if substring(@source,1,2) <> 'GL'
   	begin
   	select @errmsg = 'This batch is not associated with a GL source!', @rcode = 1
   	goto bspexit
   	end
   
   /* check Tablename */
   if substring(@tablename,1,2) <> 'GL'
   	begin
   	select @errmsg = 'This batch is not associated with a GL batch table!', @rcode = 1
   	goto bspexit
   	end
   
   /* check Status - must be 0 (open) or 4 (update in progress) */
   if @status <> 0 and @status <> 4
   	begin
   	select @errmsg = 'Invalid status - must be ''open'' or ''update in progress''.', @rcode = 1
   	goto bspexit
   	end
   
   /* check InUseBy */
   if @inuseby is not null
   	begin
   	select @errmsg = 'This batch is already in use by ' + @inuseby, @rcode = 1
   	goto bspexit
   	end
   
   /* check Restrict */
   if @restrict = 'Y' and @createdby <> SUSER_SNAME()
   	begin
   	select @errmsg = 'This batch is restricted!', @rcode = 1
   	goto bspexit
   	end
   
   /* all checks complete - set InUseBy to current user */
   update bHQBC 
   	set InUseBy = SUSER_SNAME()
   	where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Unable to update Batch Control information!', @rcode = 1
   	goto bspexit
   	end
   
   /* select some descriptive info to return to processing program */
   select Source, TableName, DateCreated, CreatedBy, Status, DatePosted
   	from bHQBC where Co = @co and Mth = @mth and BatchId = @batchid
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLBatchLock] TO [public]
GO
