SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspSLEntryMarkItemsDeleted]
  /*******************************************************************************************************
  * CREATED BY: 	 DC 2/26/07
  * MODIFIED By :  
  *
  * USAGE:  
  *		This will mark AP lines as delete.  Before 6.x this was a hard coded sql statement
  *		in SLEntry.  I did not want to leave it there and created this sp.
  *
  * INPUTS:
  *	@co
  *	@mth
  *	@batchid
  *	@seq
  *	
  *
  * OUTPUTS:
  *	@msg		
  *
  *******************************************************************************************************/
  @co bCompany, @mth bMonth, @batchid bBatchID, @seq int, @msg varchar(255) output
  as
  
  set nocount on
  
  declare @rcode int

  select @rcode = 0
    if @co is null
    	begin
    	select @msg = 'Missing PO Company!', @rcode = 1
    	goto bspexit
    	end
   if @mth is null
    	begin
    	select @msg = 'Missing Batch Month!', @rcode = 1
    	goto bspexit
    	end
   if @batchid is null
    	begin
    	select @msg = 'Missing Batch ID!', @rcode = 1
    	goto bspexit
    	end
   if @mth is null
    	begin
    	select @msg = 'Missing Batch Month!', @rcode = 1
    	goto bspexit
    	end
    	
  Update SLIB 
  set BatchTransType = 'D' 
  where Co = @co 
	and Mth = @mth
	and BatchId = @batchid 
	and BatchSeq = @seq
	and BatchTransType = 'C'
  
   
    bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspSLEntryMarkItemsDeleted] TO [public]
GO
