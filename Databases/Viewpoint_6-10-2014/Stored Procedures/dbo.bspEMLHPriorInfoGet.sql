SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMLHPriorInfoGet    Script Date: 8/28/99 9:32:42 AM ******/
   
CREATE procedure [dbo].[bspEMLHPriorInfoGet]
/***********************************************************
* CREATED BY: 	bc 06/01/99
* MODIFIED By :   bc 04/05/00  mulitple transfers per batch for a piece of equipment
*		TV 02/11/04 - 23061 added isnulls
*		TV 11/04/04 - 24980 Display the memo field from the previous transfer in the header 
*		TJL 01/19/06 - Added a few comments only. No functional code changed at this time.
* USAGE:
*
*
*
* INPUT PARAMETERS
*   EMCo        EM Co
*   Equipment
*   @date     = DateIn of current line
*   @time     = TimeIn of current line
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
@emco bCompany, @mth bMonth, @batchid bBatchID, @seq int, @equip bEquip, @date bDate = null, @time smalldatetime = null,
/* outputs */
@datein bDate = null output, @timein smalldatetime = null output,
@jcco bCompany = null output, @job bJob = null output, @loc bLoc = null output, @dateout bDate = null output,
@timeout smalldatetime = null output,  @msg varchar(255) output
   
as
set nocount on
declare @rcode int,
	@emlh_date bDate, @emlh_mth bMonth, @emlh_trans bTrans, @emlh_time smalldatetime,
	@emlb_date bDate, @emlb_seq int, @emlb_time smalldatetime,
	@LHflag bYN, @LBflag bYN
   
select @rcode = 0

/* get the most recent transfer date that has been recorded for the equipment */
select @emlh_date = null, @emlh_mth = null, @emlh_trans = null, @emlh_time = null,
	@emlb_date = null, @emlb_seq = null, @emlb_time = null,
	@LHflag = 'N', @LBflag = 'N'
   
/**** check EMLH for this equipment ****/
select @emlh_date = max(DateIn)
from dbo.EMLH with(nolock)
where EMCo = @emco and Equipment = @equip and (DateIn <= @date or @date is null)
   
if @emlh_date is not null
	begin
	/* The most recent month from the most recent prior transfer. */
	select @emlh_mth = max(Month)
	from dbo.EMLH
	where EMCo = @emco and Equipment = @equip and DateIn = @emlh_date

	/* The most recent time in from the most recent prior transfer. */
	select @emlh_time = max(TimeIn)
	from dbo.EMLH
	where EMCo = @emco and Month = @emlh_mth and Equipment = @equip and DateIn = @emlh_date

	/* The most recent transaction from the most recent prior transfer. */
	select @emlh_trans = max(Trans)
	from dbo.EMLH
	where EMCo = @emco and Month = @emlh_mth and Equipment = @equip and DateIn = @emlh_date and
		(TimeIn = @emlh_time or @emlh_time is null)
   
	if @emlh_date = @date
		begin
		select @emlh_trans = max(Trans)
		from dbo.EMLH
		where EMCo = @emco and Month = @emlh_mth and Equipment = @equip and DateIn = @emlh_date and
			isnull(TimeIn,@emlh_date + '00:00') < isnull(@time,@emlh_date + '00:00')
   
		if @emlh_trans is null
			begin
			/* Check for another prior transfer before the datein of inserted record. */
			select @emlh_date = max(DateIn)
			from dbo.EMLH
			where EMCo = @emco and Equipment = @equip and DateIn < @date
   
			if @emlh_date is null
				begin
				/* No prior transfers for this equipment. */
				select @emlh_trans = null
				end
			else
				begin
				/* At least one transfer for this equipment. */
				select @emlh_mth = max(Month)
				from dbo.EMLH
				where EMCo = @emco and Equipment = @equip and DateIn = @emlh_date

				select @emlh_trans = max(Trans)
				from dbo.EMLH
				where EMCo = @emco and Month = @emlh_mth and Equipment = @equip and DateIn = @emlh_date
				end
			end
		end
	end
   
/**** Check EMLB for this equipment ****/
select @emlb_date = max(DateIn)
from dbo.EMLB with(nolock)
where Co = @emco and Mth = @mth and BatchId = @batchid and BatchSeq <> @seq and Equipment = @equip and
	(DateIn <= @date or @date is null)
   
if @emlb_date is not null
	begin

	/* The most recent time in from the most recent prior transfer. */
	select @emlb_time = max(TimeIn)
	from dbo.EMLB with(nolock)
	where Co = @emco and Mth = @mth and BatchId = @batchid and BatchSeq <> @seq and Equipment = @equip and DateIn = @emlb_date

	/* The most recent transaction from the most recent prior transfer. */
	select @emlb_seq = max(BatchSeq)
	from dbo.EMLB with(nolock)
	where Co = @emco and Mth = @mth and BatchId = @batchid and BatchSeq <> @seq and Equipment = @equip and DateIn = @emlb_date and
		 (TimeIn = @emlb_time or @emlb_time is null)

	if @emlb_date = @date
		begin
		select @emlb_seq = max(BatchSeq)
		from dbo.EMLB with(nolock)
		where Co = @emco and Mth = @mth and BatchId = @batchid and BatchSeq <> @seq and Equipment = @equip and DateIn = @emlb_date and
		   isnull(TimeIn,@emlb_date + '00:00') < isnull(@time,@emlb_date + '00:00')

		if @emlb_seq is null
			begin
			/* Check for another prior transfer before the datein of inserted record. */
			select @emlb_date = max(DateIn)
			from dbo.EMLB with(nolock)
			where Co = @emco and Mth = @mth and BatchId = @batchid and BatchSeq <> @seq and Equipment = @equip and DateIn < @date

			if @emlb_date is null
				begin
				/* No prior transfers for this equipment. */
				select @emlb_seq = null
				end
			else
				begin
				/* At least one transfer for this equipment. */
				select @emlb_seq = max(BatchSeq)
				from dbo.EMLB with(nolock)
				where Co = @emco and Mth = @mth and BatchId = @batchid and BatchSeq <> @seq and Equipment = @equip and DateIn = @emlb_date
				end
			end
		end
	end

/* It is possible to find Prior transactions in both the Posted table EMLH and the Batch table EMLB at the same time.
   Evaluate which is the most recent Prior transaction and turnoff the other flag when appropriate. */  
if @emlb_seq is not null select @LBflag = 'Y'
if @emlh_trans is not null select @LHflag = 'Y'

if @LBflag = 'Y' and @LHflag = 'Y'
	begin
	if @emlb_date > @emlh_date select @LHflag = 'N'
	if @emlb_date < @emlh_date select @LBflag = 'N'
	if @emlb_date = @emlh_date
		begin
		if isnull(@emlb_time,@emlb_date + '00:00') > isnull(@emlh_time,@emlh_date + '00:00') select @LHflag = 'N' else select @LBflag = 'N'
		end
	end

/* Evaluation is complete.  The most recent Prior transactions has been determined.
   Get values from the appropriate table. */   
if @LHflag = 'Y'
	begin
	/* get the prior line values based on the most recent transfer date in EMLH */
	select @datein = DateIn, @timein = TimeIn, @jcco = ToJCCo, @job = ToJob, @loc = ToLocation,
		  @dateout = DateOut, @timeout = TimeOut, @msg = isnull(Memo,'')--TV 11/04/04 - 24980 
		 from dbo.EMLH with(nolock)
	where EMCo = @emco and Month = @emlh_mth and Trans = @emlh_trans
	end
   
if @LBflag = 'Y'
	begin
	/* get the prior line values based on the most recent transfer date in EMLB */
	select @datein = DateIn, @timein = TimeIn, @jcco = ToJCCo, @job = ToJob, @loc = ToLocation,
		  @dateout = DateOut, @timeout = TimeOut, @msg = isnull(Memo,'')--TV 11/04/04 - 24980 
		 from dbo.EMLB with(nolock)
	where Co = @emco and Mth = @mth and BatchId = @batchid and BatchSeq = @emlb_seq
	end
   
bspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMLHPriorInfoGet] TO [public]
GO
