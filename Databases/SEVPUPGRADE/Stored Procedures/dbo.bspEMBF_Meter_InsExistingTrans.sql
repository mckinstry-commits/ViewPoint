SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMBF_Meter_InsExistingTrans    Script Date: 3/25/2002 12:21:02 PM ******/
    /****** Object:  Stored Procedure dbo.bspEMBF_Meter_InsExistingTrans    Script Date: 8/28/99 9:36:12 AM ******/
CREATE    procedure [dbo].[bspEMBF_Meter_InsExistingTrans]
/***********************************************************
* CREATED BY:  JM 5/26/99
* MODIFIED By :JM 11/28/99 - Ref Issue 4839 - Changed select for insertion
*    into bEMBF.OldActualDate from bEMMR.ReadingDate to bEMMR.PostingDate.
*    bEMBR.OldMeterReadDate still receives bEMMR.ReadingDate.
*              MV 7/3/01 - Issue 12769 BatchUserMemoInsertExisting
*              TV 05/28/02 insert UniqueAttchID  in batch table
*              TV 12/22/03 23061 Cleanup and Adding Isnulls 
*		TRL 01/25/2010 Issue 132064 Remove Previous Meter Columns
*
* USAGE:
*	This procedure pulls existing transactions from bEMMR
*	into bEMBF for editing for Meter Reading source.
*
*	Checks batch info in bHQBC, and transaction info in bEMMR.
*	Adds entry to next available Seq# in bEMBF.
*
*	bEMBF insert trigger will update InUseBatchId in bEMMR.
*
* INPUT PARAMETERS
*	Co         EM Co to pull from
*	Mth        Month of batch
*	BatchId    Batch ID to insert transaction into
*	EMTrans         EM Trans to Pull
*	Source     EM Source
*
* OUTPUT PARAMETERS
*
* RETURN VALUE
*	0   Success
*	1   Failure
*****************************************************/
@co bCompany, @mth bMonth, @batchid bBatchID, @emtrans bTrans, @source bSource, @errmsg varchar(255) output

as

set nocount on

declare @emtranstype varchar(10), @errtext varchar(60), @glco bCompany,	@hqbcsource bSource, @inusebatchid bBatchID,
@inuseby bVPUserName, @postedmth bMonth, @rcode int, @seq int, @status tinyint

select @rcode = 0

-- Validate all params passed. 
if @co is null
begin
	select @errmsg = 'Missing Batch Company!', @rcode = 1
	goto bspexit
end
if @mth is null
begin
	select @errmsg = 'Missing Batch Month!', @rcode = 1
	goto bspexit
end
if @batchid is null
begin
	select @errmsg = 'Missing Batch ID!', @rcode = 1
	goto bspexit
end
if @emtrans is null
begin
	select @errmsg = 'Missing Batch Transaction!', @rcode = 1
	goto bspexit
end
if @source is null
begin
	select @errmsg = 'Missing Batch Source!', @rcode = 1
	goto bspexit
end

-- Validate Source. 
if @source <> 'EMMeter'
begin
	select @errmsg = isnull(@source,'') + ' is an invalid Source', @rcode = 1
	goto bspexit
end

-- Validate HQ Batch. 
exec @rcode = dbo.bspHQBatchProcessVal @co, @mth, @batchid, @source, 'EMBF', @errtext output, @status output
if @rcode <> 0
begin
	select @errmsg = @errtext, @rcode = 1
	goto bspexit
end
if @status <> 0
begin
	select @errmsg = 'Invalid Batch status - must be Open!', @rcode = 1
	goto bspexit
end

--All Transactions can be pulled into a batch as long as its InUseFlag is set to null and Month is same as current
select @inusebatchid = InUseBatchID, @postedmth=Mth from dbo.EMMR with(nolock)
where EMCo=@co and Mth = @mth and EMTrans=@emtrans
if @@rowcount = 0
begin
	select @errmsg = 'EMTrans :' + isnull(convert(varchar(10),@emtrans),'') +
	' cannot be found.' , @rcode = 1
	goto bspexit
end

if @inusebatchid is not null
begin
	select @hqbcsource=Source 	from dbo.HQBC with(nolock) 
	where Co=@co and BatchId=@inusebatchid and Mth=@mth
	if @@rowcount<>0
		begin
			select @errmsg = 'Transaction already in use by ' +
			isnuLL(convert(varchar(2),DATEPART(month, @mth)),'') + '/' +
			isnull(substring(convert(varchar(4),DATEPART(year, @mth)),3,4),'') +
			' batch # ' + isnull(convert(varchar(6),@inusebatchid),'') + ' - ' + 'Batch Source: ' +
			@hqbcsource, @rcode = 1
			goto bspexit
		end
	else
		begin
			select @errmsg='Transaction already in use by another batch!', @rcode=1
			goto bspexit
		end
end

if @postedmth <> @mth
begin
	select @errmsg = 'Cannot edit! EM transaction posted in prior month: ' +
	isnuLL(convert (varchar(60),@postedmth),'') + ',' + isnuLL(convert(varchar(60), @mth),''), @rcode = 1
	goto bspexit
end

--get GLCo from bEMCo - needed for btEMBFi trigger's insertion into bHQCC where that column can't be null 
select @glco = GLCo from dbo.EMCO  with(nolock) where EMCo = @co

-- get next available sequence # for this batch 
select @seq = isnull(max(BatchSeq),0)+1 from dbo.EMBF with(nolock)
where Co = @co and Mth = @mth and BatchId = @batchid

-- Add record back to EMBF 
insert into bEMBF (Co, Mth, BatchId, BatchSeq, Source, Equipment, EMTrans, EMTransType,BatchTransType, ActualDate, GLCo, UnitPrice, MeterReadDate,
ReplacedHourReading,
/*PreviousHourMeter, 132064*/ CurrentHourMeter, /*PreviousTotalHourMeter, 132064*/ CurrentTotalHourMeter,
ReplacedOdoReading, 
/*PreviousOdometer, 132064*/ CurrentOdometer, /*PreviousTotalOdometer, 132064*/CurrentTotalOdometer, MeterMiles, MeterHrs,
OldSource, OldEquipment, OldEMTrans, OldEMTransType, OldBatchTransType,OldActualDate, OldGLCo, OldUnitPrice,OldMeterReadDate, 
OldReplacedHourReading, /*OldPreviousHourMeter, 132064*/
OldCurrentHourMeter, /*OldPreviousTotalHourMeter, 132064*/ OldCurrentTotalHourMeter,
OldReplacedOdoReading, /*OldPreviousOdometer, 132064*/ OldCurrentOdometer,
/*OldPreviousTotalOdometer, 132064*/ OldCurrentTotalOdometer, OldMeterMiles, OldMeterHrs, UniqueAttchID )

Select @co, @mth, @batchid, @seq, @source, Equipment, @emtrans, 'Equip','C', PostingDate/*132064*/, @glco, 0, ReadingDate, 
/*isnull(PreviousTotalHourMeter,0) - isnull(PreviousHourMeter,0) 132064*/isnull(CurrentTotalHourMeter,0)-isnull(CurrentHourMeter,0),
/*isnull(PreviousHourMeter,0), 132064*/ isnull(CurrentHourMeter,0), /*isnull(PreviousTotalHourMeter,0), 132064*/ isnull(CurrentTotalHourMeter,0),
/*isnull(PreviousTotalOdometer,0) - isnull(PreviousOdometer,0), 132064*/ isnull(CurrentTotalOdometer,0)-isnull(CurrentOdometer,0),
/*isnull(PreviousOdometer,0), 132064*/ isnull(CurrentOdometer,0), /*isnull(PreviousTotalOdometer,0), */ isnull(CurrentTotalOdometer,0), Miles, Hours,
@source, Equipment, @emtrans, 'Equip', 'C', PostingDate, @glco, 0, ReadingDate,
/*isnull(PreviousTotalHourMeter,0) - isnull(PreviousHourMeter,0), */ isnull(CurrentTotalHourMeter,0)-isnull(CurrentHourMeter,0),
/*isnull(PreviousHourMeter,0), 132064*/ isnull(CurrentHourMeter,0), /*isnull(PreviousTotalHourMeter,0), 132064*/ isnull(CurrentTotalHourMeter,0),
/*isnull(PreviousTotalOdometer,0) - isnull(PreviousOdometer,0), */  isnull(CurrentTotalOdometer,0)-isnull(CurrentOdometer,0),
/*isnull(PreviousOdometer,0), 132064*/ isnull(CurrentOdometer,0), /*isnull(PreviousTotalOdometer,0), 132064*/ isnull(CurrentTotalOdometer,0), Miles, Hours,UniqueAttchID 
from dbo.EMMR with(nolock)
where EMCo=@co and Mth = @mth and EMTrans=@emtrans
if @@rowcount <> 1
begin
	select @errmsg = 'Unable to add entry to EM Batch table!', @rcode = 1
	goto bspexit
end

-- BatchUserMemoInsertExisting - update the user memo in the batch record 
exec @rcode =  dbo.bspBatchUserMemoInsertExisting @co, @mth, @batchid, @seq, 'EM MeterReadings', 0, @errmsg output
if @rcode <> 0
begin
	select @errmsg = 'Unable to update User Memos in EMBF', @rcode = 1
	goto bspexit
end

bspexit:
	if @rcode<>0 select @errmsg=@errmsg	
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMBF_Meter_InsExistingTrans] TO [public]
GO
