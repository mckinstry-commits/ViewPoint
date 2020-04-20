SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE          procedure [dbo].[bspEMPost_Meters_EMMRInserts]
/***********************************************************
* CREATED BY: JM 5/23/99
* MODIFIED By : JM 3/6/00 - Corrected loop logic; Ref Issue 6552.
*               JM 3/6/00 - Set @meterhrs and @metermiles to 0 when null to
*               prevent data error when inserted into bEMMR.Hours and bEMMR.Miles
*               when user doesn't ever use either measurement for a piece of Equipment.
*               MV 06/07/01 - Issue 12769 BatchUserMemoUpdate
*               TV/RM 02/22/02 Attachment Fix
*				GG 04/08/02 - #16702 - remove parameter from bspBatchUserMemoUpdate
*               TV 03/13/03 Clean up
*               TV 04/29/03 #21135 Added isnulls to all non nullable fields in EMMR
*				TV 02/11/04 - 23061 added isnulls
*                TV 12/04/03 18616 --reindex Attachments 
*				GP 05/26/09 - Issue 133434, removed HQAT code
*			TRL 01/21/10 - Issue 132064, removed Previuos Meter Reading Columns from proc
*
* USAGE:
* 	Called by bspEMPost_Meters_Main to insert validated entries into bEMMR.
*
* INPUT PARAMETERS
*   	EMCo        	EM Co
*   	Month       	Month of batch
*   	BatchId     	Batch ID to validate
*
* OUTPUT PARAMETERS
*   	@errmsg     	If something went wrong
*
* RETURN VALUE
*   	0   		Success
*   	1   		fail
*****************************************************/
(@co bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate, @errmsg varchar(60) output)

as
set nocount on

declare @actualdate bDate, @readingdate bDate /*132064*/, @batchseq int, @batchtranstype char(1), @currenthourmeter bHrs, @currentodometer bHrs,
@currenttotalhourmeter bHrs, @currenttotalodometer bHrs, @emtrans bTrans, @equipment bEquip,
@keyfield varchar(128), @meterhrs bHrs, @metermiles bHrs,  @rcode int, @source bSource, @updatekeyfield varchar(128),
@guid uniqueIdentifier
/*132064*/
--@previoushourmeter bHrs, @previoustotalhourmeter bHrs,
--@previousodometer bHrs, @previoustotalodometer bHrs, 

select @rcode = 0

-- Setup psuedo-cursor to loop through all rows in batch  table bEMBF to insert records in bEMMR. 		  
select @batchseq = min(BatchSeq) from dbo.EMBF with(nolock)
where Co = @co and Mth = @mth and BatchId = @batchid
   
   
-- Work thru psuedo-cursor. 
while @batchseq is not null
begin
	select @emtrans = EMTrans, @batchtranstype = BatchTransType, @source = Source, @equipment = Equipment,
	/*@actualdate = ActualDate, 132064*/ @readingdate=MeterReadDate /*132064*/, 
	@currenthourmeter = isnull(CurrentHourMeter,0),@meterhrs = isnull(MeterHrs,0), @currenttotalhourmeter = isnull(CurrentTotalHourMeter,0), 
	@currentodometer = isnull(CurrentOdometer,0),  @metermiles = isnull(MeterMiles,0),@currenttotalodometer = isnull(CurrentTotalOdometer,0), 
	@guid = UniqueAttchID
	/*132064*/ 
	--@previoushourmeter = isnull(PreviousHourMeter, 0),  
	--@previoustotalhourmeter = isnull(PreviousTotalHourMeter,0), 
	--@previousodometer = isnull(PreviousOdometer,0),  
	--@previoustotalodometer = isnull(PreviousTotalOdometer,0),
	/*132064*/             
	from dbo.EMBF with(nolock) 
	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq=@batchseq
   
BEGIN TRANSACTION
	-- For additions, add new EM Detail Transaction. 
	if @batchtranstype = 'A'
	begin
		-- Get next available transaction # for EMMR. 
		exec @emtrans = dbo.bspHQTCNextTrans 'bEMMR', @co, @mth, @errmsg output
		if @emtrans = 0
			begin
				ROLLBACK TRANSACTION
				goto get_next_batchseq
			end
		else
			begin
				-- Insert EM Meter Detail. 
				insert dbo.EMMR (EMCo, Mth, EMTrans, BatchId, Equipment, PostingDate,
				ReadingDate, Source, PreviousHourMeter, CurrentHourMeter,
				PreviousTotalHourMeter, CurrentTotalHourMeter, Hours,
				PreviousOdometer, CurrentOdometer, PreviousTotalOdometer,
				CurrentTotalOdometer, Miles, UniqueAttchID)
				values (@co, @mth, @emtrans, @batchid, @equipment, @dateposted,
				@readingdate/*132064@actualdate*/, @source, 0/*@previoushourmeter*/, @currenthourmeter,
				0/*@previoustotalhourmeter*/, @currenttotalhourmeter, @meterhrs,
				0/*@previousodometer*/, @currentodometer, 0/*@previoustotalodometer*/,
				@currenttotalodometer, @metermiles, @guid)
				if @@rowcount = 0
					begin
						ROLLBACK TRANSACTION
						goto get_next_batchseq
					end
				else
					begin 
						--update @emtrans to batch record in bEMBF for BatchUserMemoUpdate
						update dbo.EMBF 
						set EMTrans = @emtrans
						where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
					end
			end
	end
   
	-- For changes, update existing EM Meters Detail Transaction. 
	if @batchtranstype = 'C'
	begin
		update dbo.EMMR
		set BatchId = @batchid,
		Equipment = @equipment,
		PostingDate = @dateposted,		
		ReadingDate = @readingdate/*132064@actualdate*/,
		Source = @source,
		PreviousHourMeter = 0/*@previoushourmeter*/,
		CurrentHourMeter = @currenthourmeter,
		PreviousTotalHourMeter = 0/*@previoustotalhourmeter*/,
		CurrentTotalHourMeter = @currenttotalhourmeter,
		Hours = @meterhrs,
		PreviousOdometer = 0/*@previousodometer*/,
		CurrentOdometer = @currentodometer,	
		CurrentTotalOdometer = @currenttotalodometer,
		PreviousTotalOdometer = 0/*@previoustotalodometer*/,
		Miles = @metermiles,
		InUseBatchID = null,
		UniqueAttchID = @guid
		where EMCo = @co and Mth = @mth and EMTrans = @emtrans
		if @@rowcount = 0
		begin
			ROLLBACK TRANSACTION
			goto get_next_batchseq
		end
	end
   
   	-- For deletions, delete existing EM Detail Transaction. 
   	if @batchtranstype = 'D'
   	begin
   		delete dbo.EMMR
   		where EMCo = @co and Mth = @mth and EMTrans = @emtrans
   		if @@rowcount = 0
   		begin
   			ROLLBACK TRANSACTION
   			goto get_next_batchseq
   		end
      end
   
	--call bspBatchUserMemoUpdate to update user memos in bEMMR before deleting the batch record
	if @batchtranstype in ('A','C')
	begin
		exec @rcode = dbo.bspBatchUserMemoUpdate @co, @mth, @batchid, @batchseq, 'EM MeterReadings', @errmsg output
		if @rcode <> 0
	    begin
			select @errmsg = 'Unable to update User Memo in EMMR.', @rcode = 1
			ROLLBACK TRANSACTION
			goto get_next_batchseq
	    end
	 end
   
   	-- Delete current row from bEMBF and commit transaction. 
   	delete from dbo.EMBF
   	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
   	
COMMIT TRANSACTION
   
	get_next_batchseq:

	-- Get next BatchSeq for psuedo-cursor. 
	select @batchseq = min(BatchSeq) from dbo.EMBF with(nolock)
	where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq > @batchseq
	
end -- While loop on BatchSeq pseudo-cursor 

-- Make sure batch is empty. 
if exists(select * from dbo.EMBF with(nolock) where Co = @co and Mth = @mth and BatchId = @batchid)
begin
	select @errmsg = 'Not all EM batch entries were posted - unable to close batch!', @rcode = 1
	goto bspexit
end

bspexit:
	if @rcode<>0 select @errmsg=isnull(@errmsg,'')	
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMPost_Meters_EMMRInserts] TO [public]
GO
