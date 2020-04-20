SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[vspAPLBLinesMarkDeleted]
  /***************************************************
  * CREATED BY    : MV 
  *	CREATED ON	  : 05/22/06
  * LAST MODIFIED : 
  * Usage:
  *   Marks all AP Lines for a given header as "D" - deleted when 
  *   the header rec is marked as "D"
  *
  * Input:
  *	@co         
  *	@batchmth
  * @batchid      
  * @seq
  *
  * Output:
  *   @msg         
  *
  * Returns:
  *	0             success
  * 1             error
  *************************************************/
  	(@co bCompany = null, @batchmth bMonth, @batchid integer,@seq integer, @msg varchar(60) output)
  as
  
  set nocount on
  
  declare @rcode int
  
  select @rcode = 0
  
  if @co is null
  	begin
  	select @msg = 'Missing AP Company', @rcode = 1
  	goto bspexit
  	end
  
  if @batchmth is null
  	begin
  	select @msg = 'Missing Batch Month', @rcode = 1
  	goto bspexit
  	end
  
 if @batchid is null
  	begin
  	select @msg = 'Missing BatchId', @rcode = 1
  	goto bspexit
  	end

if @seq is null
  	begin
  	select @msg = 'Missing Batch Seq', @rcode = 1
  	goto bspexit
  	end

Update APLB set BatchTransType = 'D' where Co=@co and Mth=@batchmth and BatchId=@batchid
         and BatchSeq =@seq and BatchTransType='C'
if @@rowcount = 0
	begin
	select @msg = 'Lines were not marked as ''Deleted''.', @rcode = 1
  	goto bspexit
  	end
 
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPLBLinesMarkDeleted] TO [public]
GO
