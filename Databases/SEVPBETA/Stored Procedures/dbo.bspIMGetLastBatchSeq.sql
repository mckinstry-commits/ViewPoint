SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspIMGetLastBatchSeq    Script Date: 5/20/2002 10:04:28 AM ******/
   
   CREATE               procedure [dbo].[bspIMGetLastBatchSeq]
   /************************************************************************
   * CREATED:  mh 5/9/2002    
   * MODIFIED: DANF 02/25/08 - Issue 126670 Correct next sequence for where data security may be involved.
   *
   * Purpose of Stored Procedure
   *
   *    Get the last batch sequence number
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
   
       (@co bCompany, @mth bMonth, @batchid bBatchID, @tablename varchar(5), 
   	@maxbatchid int output, @msg varchar(80) = '' output)
    WITH EXECUTE AS 'viewpointcs'
   as
   set nocount on
   

       declare @insertstmt nvarchar(1000), @batchmth varchar(30), @rcode int, @rowcountparamsin nvarchar(200)
        select @batchmth = @mth
   select @rcode = 0
    
   
   -- -- -- define parameters for exec sql statement 
	set @rowcountparamsin = N'@co tinyint, @batchmth smalldatetime, @batchid int, @validcnt int OUTPUT'
    
	select @rcode = 0, @maxbatchid = null
   
   	if @co is null
   	begin
   		select @msg = 'Missing Company.', @rcode = 1
   		goto bspexit
   	end
   
   	if @mth is null
   	begin
   		select @msg = 'Missing Month.', @rcode = 1
   		goto bspexit
   	end
   
   	if @batchid is null
   	begin
   		select @msg = 'Missing Batch ID.', @rcode = 1
   		goto bspexit
   	end
   
   	if @tablename is null
   	begin
   		select @msg = 'Missing Tablename.', @rcode = 1
   		goto bspexit
   	end
   

    -- check to make sure there are records in this table. If not, then exit
	select @insertstmt = 'select @validcnt=isnull(max(BatchSeq),0) from b' + 
   	@tablename + ' where Co = @co and Mth = @batchmth and BatchId = @batchid'

    exec sp_executesql @insertstmt, @rowcountparamsin, 
       @co, @batchmth, @batchid, @validcnt = @maxbatchid OUTPUT

   
   	if @maxbatchid = null
   	begin
   		select @msg = 'Unable to get BatchSeq.'
   		select @rcode = 1
   	end
   	else
   	begin
   
   		if @maxbatchid is null
   			select @maxbatchid = 0
   	end
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMGetLastBatchSeq] TO [public]
GO
