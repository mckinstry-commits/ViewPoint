SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     procedure [dbo].[bspEMVal_Meters_ChangedDeleted]
/***********************************************************
* CREATED BY: JM 5/23/99
* MODIFIED By : 09/17/01 JM - Changed creation method for temp tables from 'select * into' to discrete declaration
*	of specific fields. Also changed inserts into temp tables to discrete declaration of fields. 
*	Ref Issue 14227.
*	TV 02/16/04 - 23061 added isnulls and other cleanup
*
* USAGE:
* 	Called by bspEMVal_Meters_Main to run validation applicable
*	only to Changed and Deleted records.
*
* INPUT PARAMETERS
*	EMCo        EM Company
*	Month       Month of batch
*	BatchId     Batch ID to validate
*	BatchSeq    Batch Seq to validate
*
* OUTPUT PARAMETERS
*	@errmsg     if something went wrong
*
* RETURN VALUE
*	0   Success
*	1   Failure
*****************************************************/
@co bCompany, @mth bMonth, @batchid bBatchID, @batchseq int, @errmsg varchar(255) output

as

set nocount on

declare @emmrbatchid bBatchID,	@emmrcurrenthourmeter bHrs,	@emmrcurrentodometer bHrs,	@emmrcurrenttotalhourmeter bHrs,
@emmrcurrenttotalodometer bHrs,	@emmremtrans bTrans, @emmrequipment bEquip,	@emmrhours bHrs, @emmrinusebatchid bBatchID,
@emmrmiles bHrs, @emmrpostingdate bDate, @emmrprevioushourmeter bHrs, @emmrpreviousodometer bHrs, @emmrprevioustotalhourmeter bHrs,
@emmrprevioustotalodometer bHrs, @emmrreadingdate bDate, @emmrsource bSource, @emtrans bTrans, @errorstart varchar(50),
@errtext varchar(255), @oldactualdate bDate, @oldbatchid bBatchID, @oldcurrenthourmeter bHrs, @oldcurrentodometer bHrs,
@oldcurrenttotalhourmeter bHrs,	@oldcurrenttotalodometer bHrs, @oldemtrans bTrans, 	@oldequipment bEquip, @oldhours bHrs,
@oldinusebatchid bBatchID, @oldmiles bHrs, @oldpostingdate bDate, @oldprevioushourmeter bHrs, @oldpreviousodometer bHrs,
@oldprevioustotalhourmeter bHrs, @oldprevioustotalodometer bHrs, @oldreadingdate bDate, @oldsource bSource,	 @rcode int

select @rcode = 0

/* Verify parameters passed in. */
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
	select @errmsg = 'Missing BatchID!', @rcode = 1
	goto bspexit
end
if @batchseq is null
begin
	select @errmsg = 'Missing Batch Sequence!', @rcode = 1
	goto bspexit
end

--Not Needed TV 2/16/04
/* Create and fill temp table with record to be validated.*/


--This again, ain't no Psuedo-Cursor TV 2/16/04
/* Fetch row data from psuedo-cursor into variables. */
/* First get values used in summary calcs. */
select 	/*@oldprevioushourmeter = OldPreviousHourMeter , 132064*/
@oldcurrenthourmeter = OldCurrentHourMeter,
/*@oldpreviousodometer = OldPreviousOdometer,  132064*/
@oldcurrentodometer = OldCurrentOdometer,
@emtrans = EMTrans,
@oldbatchid = BatchId,
@oldequipment = OldEquipment,
@oldactualdate = OldActualDate,
@oldreadingdate = OldMeterReadDate,
@oldsource = OldSource,
@oldemtrans = OldEMTrans,
/*@oldprevioustotalhourmeter = OldPreviousTotalHourMeter,  132064*/
@oldcurrenttotalhourmeter = OldCurrentTotalHourMeter,
@oldhours = OldMeterHrs ,/*isnull(@oldcurrenthourmeter,0) - isnull(@oldprevioushourmeter,0), 132064*/
/*@oldprevioustotalodometer = OldPreviousTotalOdometer,  132064*/
@oldcurrenttotalodometer = OldCurrentTotalOdometer,
@oldmiles = OldMeterMiles /*isnull(@oldcurrentodometer,0) - isnull(@oldpreviousodometer,0) 132064*/
--from #ValRec
from dbo.EMBF with(nolock)
where Co = @co and Mth = @mth And BatchId = @batchid and BatchSeq = @batchseq

-- Setup @errorstart string. 
select @errorstart = 'Seq ' + isnull(convert(varchar(9),@batchseq),'') + '-'

-- Get existing values from EMMR. 
select 	@emmremtrans = EMTrans,
@emmrsource = Source,
@emmrequipment = Equipment,
@emmrpostingdate = PostingDate,
@emmrreadingdate = ReadingDate,
/*@emmrprevioushourmeter = PreviousHourMeter,  132064*/
@emmrcurrenthourmeter = CurrentHourMeter,
/*@emmrprevioustotalhourmeter = PreviousTotalHourMeter,  132064*/
@emmrcurrenttotalhourmeter = CurrentTotalHourMeter,
@emmrhours = Hours,
/*@emmrpreviousodometer = PreviousOdometer,  132064*/
@emmrcurrentodometer = CurrentOdometer,
/*@emmrprevioustotalodometer = PreviousTotalOdometer,*/
@emmrcurrenttotalodometer = CurrentTotalOdometer,
@emmrmiles = Miles,
@emmrinusebatchid = InUseBatchID
from dbo.EMMR with(nolock) where EMCo = @co and Mth = @mth and EMTrans = @emtrans

if @@rowcount = 0
begin
	select @errtext = isnull(@errorstart,'') + '-Missing EM Meter Transaction #:' + isnull(convert(char(3),@emtrans),'')
	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
	if @rcode <> 0
	begin
		select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
		goto bspexit
	end
end

/* Verify EMMR record assigned to same BatchId. */
if @emmrinusebatchid <> @batchid
begin
	select @errtext = isnull(@errorstart,'') + '- Meter Transaction has not been assigned to this BatchId.'
	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
	if @rcode <> 0
	begin
		select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
		goto bspexit
	end
end



/* Make sure old values in batch match existing values in meter detail table bEMMR. */
if isnull(@emmrinusebatchid,0) <> @oldbatchid
or @emmremtrans <> @oldemtrans
or @emmrequipment <> @oldequipment
or @emmrpostingdate <> @oldactualdate
or @emmrreadingdate <> @oldreadingdate
or @emmrsource <> @oldsource
/*or @emmrprevioushourmeter <> @oldprevioushourmeter 132064*/
or @emmrcurrenthourmeter <> @oldcurrenthourmeter
/*or @emmrprevioustotalhourmeter <> @oldprevioustotalhourmeter  132064*/
or @emmrcurrenttotalhourmeter <> @oldcurrenttotalhourmeter
or @emmrhours <> @oldhours
/*or @emmrpreviousodometer <> @oldpreviousodometer 132064*/
or @emmrcurrentodometer <> @oldcurrentodometer
/*or @emmrprevioustotalodometer <> @oldprevioustotalodometer  132064*/
or @emmrcurrenttotalodometer <> @oldcurrenttotalodometer
or @emmrmiles <> @oldmiles
begin
	select @errtext = isnull(@errorstart,'') + '-Batch Old info does not match EM Meter Detail.'
	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
	if @rcode <> 0
	begin
	select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
	goto bspexit
	end
end



/* **************************** */
/* Validate old values in EMBF. */
/* **************************** */

exec @rcode = dbo.bspEMEquipValForMeterReadingsChangedDeleted @co, @oldequipment, @errmsg output
if @rcode = 1
begin
	select @errtext = isnull(@errorstart,'') + 'OldEquipment ' + isnull(@oldequipment,'') + '-' + isnull(@errmsg,'')
	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
	if @rcode <> 0
	begin
		select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
		goto bspexit
	end
end

bspexit:
if @rcode<>0 select @errmsg=isnull(@errmsg,'')	--+ char(13) + char(10) + '[bspEMVal_Meters_ChangedDeleted]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMVal_Meters_ChangedDeleted] TO [public]
GO
