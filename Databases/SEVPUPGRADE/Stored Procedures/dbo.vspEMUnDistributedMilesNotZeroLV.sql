SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [dbo].[vspEMUnDistributedMilesNotZeroLV]
/***********************************************************
* CREATED BY	: Toml 04/03/07 - Issue #27992, 6x Rewrite
* MODIFIED BY	
*
* USAGE:
* 	Retrieves the Sequences in a Batch where UnDistributed miles is not 0.0 and
*	fills a ListView to be displayed to user just prior to opening Batch Processing form.
*
*
* INPUT PARAMETERS:
*	EMCo  
*	BatchMth
*	BatchId
*
* OUTPUT PARAMETERS:
*	
*
*****************************************************/
(@emco bCompany, @batchmth bMonth, @batchid int)

as

set nocount on

declare @rcode int, @batchseq int, @undistributed bHrs, @totalmiles bHrs, @loaded bHrs, @unloaded bHrs, @offroad bHrs,
	@equipment bEquip, @remarks varchar(30), @openseqcursor int

select @rcode = 0, @undistributed = 0, @totalmiles = 0, @loaded = 0, @unloaded = 0, @offroad = 0,
	@equipment = null, @remarks = '', @openseqcursor = 0

declare @NotDistributed table
(
	Seq Int not null,
	Equipment bEquip not null,
	TotalMiles bHrs not null,
	Undistributed bHrs not null,
	Remarks varchar(30) null
)

declare bcSeq cursor local fast_forward for
select BatchSeq
from bEMMH with (nolock)
where Co = @emco and Mth = @batchmth and BatchId = @batchid
order by BatchSeq

open bcSeq
select @openseqcursor = 1

fetch next from bcSeq into @batchseq
while @@fetch_status = 0
	begin	/* Begin Seq Loop */
	/* Reset */
	select @equipment = null, @remarks = '', @undistributed = 0, @totalmiles = 0, @loaded = 0, @unloaded = 0, @offroad = 0

	select @equipment = Equipment, @totalmiles = EndOdo - BeginOdo
	from bEMMH with (nolock)
	where Co = @emco and Mth = @batchmth and BatchId = @batchid and BatchSeq = @batchseq
	if @@rowcount = 0
		begin
		select @undistributed = 0
		end

	select @loaded = sum(OnRoadLoaded), @unloaded = sum(OnRoadUnLoaded), @offroad = sum(OffRoad)
	from bEMML with (nolock)
	where Co = @emco and Mth = @batchmth and BatchId = @batchid and BatchSeq = @batchseq
	if @@rowcount = 0
		begin
		select @loaded = 0, @unloaded = 0, @offroad = 0
		end

	select @undistributed = isnull(@totalmiles, 0) - (isnull(@loaded, 0) + isnull(@unloaded, 0) + isnull(@offroad, 0))

	If @undistributed <> 0
		begin
		If @undistributed < 0
			begin
			select @remarks = 'Overdistributed'
			end
		Insert into @NotDistributed(Seq, Equipment, TotalMiles, Undistributed, Remarks)
		values(@batchseq, @equipment, @totalmiles, @undistributed, @remarks)
		end

nextseq:
	fetch next from bcSeq into @batchseq
	end		/* End Seq Loop */

If exists(select 1 from @NotDistributed)
	begin
	select *
	from @NotDistributed
	order by Seq
	select @rcode = 1
	end

vspexit:

if @openseqcursor = 1
	begin
	close bcSeq
	deallocate bcSeq
	select @openseqcursor = 0
	end

return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMUnDistributedMilesNotZeroLV] TO [public]
GO
