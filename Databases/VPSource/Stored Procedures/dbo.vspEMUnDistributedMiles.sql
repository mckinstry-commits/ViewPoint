SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [dbo].[vspEMUnDistributedMiles]
/***********************************************************
* CREATED BY	: Toml 04/03/07 - Issue #27992, 6x Rewrite
* MODIFIED BY	
*
* USAGE:
* 	Retrieves the UnDistributed miles for a BatchSeq.
*
*
* INPUT PARAMETERS:
*	EMCo  
*	BatchMth
*	BatchId
*	BatchSeq
*
* OUTPUT PARAMETERS:
*	UnDistributed
*
*****************************************************/
(@emco bCompany, @batchmth bMonth, @batchid int, @batchseq int, @undistributed bHrs output, @errmsg varchar(255) output)

as

set nocount on

declare @rcode int, @totalmiles bHrs, @loaded bHrs, @unloaded bHrs, @offroad bHrs
select @rcode = 0, @undistributed = 0, @totalmiles = 0, @loaded = 0, @unloaded = 0, @offroad = 0

if @emco is null
	begin
	select @errmsg = 'Missing EMCo.', @rcode = 1
	goto vspexit
	end
if @batchmth is null
	begin
	select @errmsg = 'Missing BatchMonth.', @rcode = 1
	goto vspexit
	end
if @batchid is null
	begin
	select @errmsg = 'Missing BatchId.', @rcode = 1
	goto vspexit
	end
if @batchseq is null
	begin
	select @errmsg = 'Missing BatchSeq.', @rcode = 1
	goto vspexit
	end

select @totalmiles = EndOdo - BeginOdo
from bEMMH with (nolock)
where Co = @emco and Mth = @batchmth and BatchId = @batchid and BatchSeq = @batchseq
if @@rowcount = 0
	begin
	/* There cannot be an UnDistributed value without at least a Header record. */
	select @undistributed = 0
	goto vspexit
	end

select @loaded = sum(OnRoadLoaded), @unloaded = sum(OnRoadUnLoaded), @offroad = sum(OffRoad)
from bEMML with (nolock)
where Co = @emco and Mth = @batchmth and BatchId = @batchid and BatchSeq = @batchseq
if @@rowcount = 0
	begin
	/* There can be an UnDistributed value without detail records.  Set detail values to zero and proceed. */
	select @loaded = 0, @unloaded = 0, @offroad = 0
	end

select @undistributed = isnull(@totalmiles, 0) - (isnull(@loaded, 0) + isnull(@unloaded, 0) + isnull(@offroad, 0))

vspexit:

return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMUnDistributedMiles] TO [public]
GO
