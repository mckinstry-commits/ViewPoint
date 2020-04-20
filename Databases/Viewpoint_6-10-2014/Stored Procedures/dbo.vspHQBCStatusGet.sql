SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspHQBCStatusGet]
/********************************
* Created: GG 02/19/07
* Modified: 
*
* Called by standards to get the Status of a Batch.
*
* Input:
*	@co			HQ Company #
*	@mth		Batch Month
*	@batchid	Batch ID#
*
* Output:
*	@status		Batch Status
*	@errmsg		Error message if failure

* Return code:
*	0 = success, 1 = failure
*
*********************************/
	(@co tinyint = null, @mth bMonth = null, @batchid bBatchID = null, 
	 @status tinyint output, @errmsg varchar(60) output)
as

set nocount on
declare @rcode int
set @rcode = 0

-- get Batch Status
select @status = Status 
from dbo.bHQBC (nolock)
where Co = @co and Mth = @mth and BatchId = @batchid 
if @@rowcount = 0
	begin
	select @errmsg = 'Invalid Batch.', @rcode = 1
	goto vspexit
	end

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQBCStatusGet] TO [public]
GO
