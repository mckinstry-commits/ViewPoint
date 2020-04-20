SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspEMBFClear    Script Date:  ******/
CREATE procedure [dbo].[vspEMBFClear]
/***********************************************************
* CREATED BY:  TJL 11/22/06 - Issue #28041, 6x Recode
* MODIFIED By : 
*
*
* USAGE: Automatically clears EMBF table if AutoUsage processing procedure fails.
*
*
*
* INPUT PARAMETERS
*   EMCo        EM Co
*   Month       Month of batch
*   BatchId     Batch ID to validate
*
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
*
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
@emco bCompany, @mth bMonth, @batchid bBatchID, @errmsg varchar(255) output
as
set nocount on

declare @rcode int
select @rcode = 0

if @emco is null 
	begin
	select @errmsg = 'Missing EM Company.', @rcode = 1
	goto vspexit
	end
if @mth is null 
	begin
	select @errmsg = 'Missing BatchMonth.', @rcode = 1
	goto vspexit
	end
if @batchid is null 
	begin
	select @errmsg = 'Missing BatchId.', @rcode = 1
	goto vspexit
	end

if exists(select 1 from bEMBF with (nolock) where Co = @emco and Mth = @mth and BatchId = @batchid)
	begin
	delete bEMBF
	where Co = @emco and Mth = @mth and BatchId = @batchid
	
	if exists(select 1 from bEMBF with (nolock) where Co = @emco and Mth = @mth and BatchId = @batchid)
		begin
		select @errmsg = 'Not all batch records were deleted successfully.', @rcode = 1
		goto vspexit
		end
	end

vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMBFClear] TO [public]
GO
