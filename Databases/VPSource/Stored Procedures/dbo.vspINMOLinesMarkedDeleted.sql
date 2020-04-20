SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspINMOLinesMarkedDeleted]

  /*************************************
  * CREATED BY:  TRL 11/29/05
  * Modified By:
  *
  * Used By form INMOEntryItems
  *
  * Pass:
  *   Co - Inventory Company  
  *   Mth - Batch Month
  *  Batch ID
  *  Seq
  *
  * Success returns:
  *
  *
  * Error returns:
  *	1 and error message
  **************************************/
  (@co bCompany = null,  @mth smalldatetime = null, @batchid int = 0, @seq int =0,@msg varchar(256) output)
  as
  set nocount on
  
  declare @rcode int
  
  select @rcode = 0
  
  if @co is null
  	begin
  	select @msg = 'Missing IN Company', @rcode = 1
  	goto vspexit
  	end
If @mth is null
  	begin
  	select @msg = 'Missing Month', @rcode = 1
  	goto vspexit
  	end
If IsNull(@batchid,0) = 0
  	begin
  	select @msg = 'Missing Batch Id', @rcode = 1
  	goto vspexit
  	end
If  isnull(@seq,0)=0
  	begin
  	select @msg = 'Missing Sequence', @rcode = 1 
  	goto vspexit
  	end

--Mark lines to delete
Update INIB 
Set BatchTransType = 'D' 
Where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq  and BatchTransType='C'

--  if @@rowcount = 0
--      begin
--      select @msg='No Items to marked for deletion. ', @rcode=1
--      goto vspexit
--      end

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspINMOLinesMarkedDeleted] TO [public]
GO
