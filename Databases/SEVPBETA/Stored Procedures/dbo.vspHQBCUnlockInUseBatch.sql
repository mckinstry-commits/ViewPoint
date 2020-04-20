SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspHQBCUnlockInUseBatch]
/**************************************************************
* Created: ??
* Modified: GG 03/27/08 - added validation and error messages
*
* Used by Batch Selection form to unlock an HQBC Batch Control record
*
* Inputs:
*	@co			Company
*	@mth		Batch Month
*	@batchid	Batch ID#
*
* Outputs:
*	@errmsg		Error message
*
* Return Code:
*	@rcode		0 = success, 1 = error
*
***************************************************************/
   
  @co bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @errmsg varchar(255) output
   
as
set nocount on
declare  @inuseby bVPUserName, @rcode int
   	
select @rcode = 0
   
-- validate HQ Batch Control entry
select @inuseby = InUseBy
from dbo.bHQBC
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
	begin
	select @errmsg = 'Missing HQ Batch control entry.', @rcode = 1
	goto vspexit
	end
if isnull(@inuseby,suser_name()) <> suser_name() and suser_name() <> 'viewpointcs'
	begin
	select @errmsg = 'You can only unlock batches you currently have ''in use''.', @rcode = 1
	goto vspexit
	end
	
-- Unlock HQ Batch Control	
update dbo.bHQBC
set InUseBy = null
where Co = @co and Mth = @mth and BatchId = @batchid

	
vspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQBCUnlockInUseBatch] TO [public]
GO
