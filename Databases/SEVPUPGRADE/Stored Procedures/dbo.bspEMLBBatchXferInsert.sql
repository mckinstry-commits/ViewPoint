SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspEMLBBatchXferInsert]
/***********************************************************
* CREATED BY: 	 bc 06/24/99
* MODIFIED By : TV 02/11/04 - 23061 added isnulls
*		TJL 01/26/07 - Issue #28024, 6x Rewrite EMLocXferBatch form.  Using FromJCCo, FromJob, FromLoc from
*								the EMLocXferBatch form is incorrect.  Must Come from EMEM for each Equip.  Corrected	
*
* USAGE:  Inserts a multiple pieces of equipment into EMLB.
*         The EMLB insert trigger will insert any attachments this equipment may have.
*
* INPUT PARAMETERS
*   EMCo        EM Co
*   Month       Month of batch
*   BatchId     Batch ID to validate
*   Equipment
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
@emco bCompany, @mth bMonth, @batchid bBatchID, @equiplist varchar(8000), @tojcco bCompany = null, @tojob bJob = null, @toloc bLoc = null,
@datein bDate, @timein smalldatetime = null, @estdateout bDate = null, @msg varchar(255) output
as

set nocount on

declare @rcode int, @seq int, @x int, @equip bEquip, @fromjcco bCompany, @fromjob bJob, @fromloc bLoc

select @rcode = 0, @x = 0
/* Parse out each piece of Equipment from Equipment list passed in. Process Each. */
while len(@equiplist) <> 0
begin
	select @x = charindex(',', @equiplist)
	select @equip = substring(@equiplist, 1, @x - 1)

	/* Prevent the Mass Transfer program from transfering a piece of equipment more than once in a batch. */
	if exists(select 1 from bEMLB with (nolock) where Mth = @mth and BatchId = @batchid and Equipment = @equip)
	begin
		goto NextEquipment
	end

	/* Get from information, for each Equipment, from EMEM. */
	select @fromjcco = JCCo, @fromjob = Job, @fromloc = Location from bEMEM with (nolock)
	where EMCo = @emco and Equipment = @equip

	/* Get the latest sequence number. */ 
	select @seq = isnull(max(BatchSeq),0) + 1 from bEMLB with (nolock)
	where Co = @emco and Mth = @mth and BatchId = @batchid

	/* Insert equipment. */
	begin transaction
		insert into bEMLB (Co, Mth, BatchId, BatchSeq, Source, Equipment, BatchTransType, FromJCCo,
		FromJob, ToJCCo, ToJob, FromLocation, ToLocation, DateIn, TimeIn, EstOut)
		values(@emco, @mth, @batchid, @seq, 'EMXfer', @equip,'A', @fromjcco,
		@fromjob, @tojcco, @tojob, @fromloc, @toloc, @datein, @timein, @estdateout)
		if @@rowcount = 1
			begin
				commit transaction
			end
		else
			begin
				select @msg = 'Batch record insert failed on Equipment ' + @equip + '.', @rcode = 1
				rollback transaction
				goto bspexit
			end

NextEquipment:
select @equiplist = substring(@equiplist, @x + 1, (len(@equiplist) - @x))
end

bspexit:
if @rcode <> 0 select @msg = isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMLBBatchXferInsert]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMLBBatchXferInsert] TO [public]
GO
