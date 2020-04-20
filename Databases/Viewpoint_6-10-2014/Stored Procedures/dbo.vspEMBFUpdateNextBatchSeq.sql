SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[vspEMBFUpdateNextBatchSeq]  
/***********************************************************
* CREATED BY:  TRL 02/09/2010 Issue 132064
* MODIFIED By :	GF 01/07/2013 tk-20627 change to where clause for hours max reading date
*
*
* USAGE:  Updates Meter changes for the Next Meter Reading Date/Batch Seq
* Procedure executes from EMBF Insert/Update/Delete triggers
*
* INPUT PARAMETERS
*@emco		EM Company
*@mth        
*@batchid
*@seq 
*@batchtranstype
*@emtrans    
*@equip		Equipment to be validated
*@readingdate 
*@odometer 	
*@hourmeter  
*@msg					Description or Error msg if error
**********************************************************/
(@emco bCompany = null, @mth bMonth = null,@batchid bBatchID, @seq int=null,@batchtranstype varchar(1)=null,@emtrans bTrans = null, 
@deletetriggerYN bYN = null, @equip bEquip = null,@readingdate bDate = null,
@currenthourmeter bHrs = null, @currentodometer bHrs = null,  @msg varchar(255) output)

as

set nocount on

declare @rcode int,
/*Variables used to get last and next Odo/Hours meter readings for the Meter Reading Date @readingdate*/
@emmr_min_readingdate bDate, @emmr_min_mth bMonth, @emmr_min_trans bTrans, 
@embf_min_readingdate bDate, @embf_min_seq int, 
@emmr_max_readingdate bDate, @emmr_max_mth bMonth, @emmr_max_trans bTrans, 
@embf_max_readingdate bDate,@embf_max_seq int 

select @rcode = 0

if @emco is null
begin
	select @msg = 'Missing EM Company!', @rcode = 1
	goto bspexit
end

if isnull(@equip,'')=''
begin
	select @msg = 'Missing Equipment!', @rcode = 1
	goto bspexit
end

if isnull(@readingdate,'')=''
begin
	select @msg = 'Missing Reading Date!', @rcode = 1
	goto bspexit
end

if datediff(month, @readingdate,@mth) < 0
begin
	select @msg = 'Reading Date must equal to or less than the last day of the Batch Month!', @rcode = 1
	goto bspexit
end

--Return if Equipment Change in progress for New Equipment Code
exec @rcode = vspEMEquipChangeInProgressVal @emco, @equip, @msg output
If @rcode = 1
	begin
	goto bspexit
end

--Set variables 
select @emmr_min_readingdate=null, @emmr_min_mth=null, @emmr_min_trans =null, 
@embf_min_readingdate =null, @embf_min_seq =null, 
@emmr_max_readingdate =null, @emmr_max_mth =null, @emmr_max_trans =null, 
@embf_max_readingdate =null,@embf_max_seq = null 

/*START HOUR METER READING HISTORY EMMR/EMBF*/
----Get Next Odometer Historical Reading EMMR for hours
----TK-20627 change where clause to use hours <> 0 
select @emmr_max_readingdate = min(ReadingDate)
from dbo.EMMR with(nolock)
where EMCo = @emco 
	AND Equipment = @equip 
	AND ReadingDate > @readingdate 
	AND [Source] = 'EMMeter'
	AND Hours <> 0

 --Get Next Batch Hour Meter Reading from EMBF
select @embf_max_readingdate = min(MeterReadDate) from dbo.EMBF  
where Co = @emco and Mth = @mth and BatchId = @batchid  and BatchSeq <> @seq 
and Equipment = @equip and MeterReadDate > @readingdate and [Source] = 'EMMeter' and MeterHrs <> 0

--If next meter reading exists in the batch check to see if we need to update it
if IsNull(@embf_max_readingdate,'') <> ''
begin
	/*1.  Check to see if multiple change records exists so we can update the following records, need to ajust meter reading next meter reading*/
	if (isnull(@emmr_max_readingdate,'') <> '' and isnull(@emmr_max_readingdate,'') = IsNull(@embf_max_readingdate,'') 
	and isnull(@batchtranstype,'') in( 'C','D') and @emtrans is not null) 
	/*2.  If entering new multiple meter readings batch, need to ajust meter reading next meter reading*/
	or (isnull(@emmr_max_readingdate,'') = '' and isnull(@batchtranstype,'') = 'A' )
	begin
		/*If delete trigger, we need to tie previous and next meter readings in the current batch*/
		if isnull(@deletetriggerYN,'') = 'Y' and isnull(@batchtranstype,'') = 'A' 
		begin 
			 --Get Last Odometer Reading from EMBF 
			select @embf_min_readingdate = max(MeterReadDate) from dbo.EMBF 
			where Co = @emco and Mth = @mth and BatchId = @batchid and BatchSeq <> @seq 
			and Equipment = @equip and MeterReadDate <@readingdate 	and [Source] = 'EMMeter'  and MeterHrs <> 0 
			
			if isnull(@embf_min_readingdate,'') <> '' 
			begin
				/* the most recent meter reading from the current batch */
				select @embf_min_seq = max(BatchSeq)	from dbo.EMBF with(nolock)
				where Co = @emco and Mth = @mth and BatchId = @batchid and BatchSeq <> @seq 
				and Equipment = @equip and MeterReadDate = @embf_min_readingdate and [Source] = 'EMMeter'    and MeterHrs <> 0 
			
				select  @currenthourmeter =CurrentHourMeter
				from dbo.EMBF  with(nolock)
				where Co = @emco and Mth = @mth and BatchId = @batchid  and BatchSeq =@embf_min_seq and BatchSeq <> @seq 
				and Equipment = @equip and MeterReadDate = @embf_min_readingdate  and Source = 'EMMeter'    and MeterHrs <> 0 
			end 
		end
		
		/* the most recent transaction from the most recent prior transfer */
		select @embf_max_seq = min(BatchSeq)	from dbo.EMBF with(nolock)
		where Co = @emco and Mth = @mth and BatchId = @batchid and BatchSeq <> @seq 
		and Equipment = @equip and MeterReadDate = @embf_max_readingdate and [Source] = 'EMMeter'   and MeterHrs <> 0 
	
		update dbo.EMBF  
		set MeterHrs = CurrentHourMeter-@currenthourmeter 
		where Co = @emco and Mth = @mth and BatchId = @batchid  and BatchSeq <> @seq and BatchSeq = @embf_max_seq
		and Equipment = @equip and MeterReadDate = @embf_max_readingdate and Source = 'EMMeter'   and MeterHrs <> 0
	
	end
end
/*END HOUR METER READING HISTORY EMMR/EMBF*/

--Reset variables 
select @emmr_min_readingdate=null, @emmr_min_mth=null, @emmr_min_trans =null, 
@embf_min_readingdate =null, @embf_min_seq =null, 
@emmr_max_readingdate =null, @emmr_max_mth =null, @emmr_max_trans =null, 
@embf_max_readingdate =null,@embf_max_seq = null 

/*START ODOMETER READING HISTORY EMBF*/
--Get Next Odometer Reading (EMMR)
select @emmr_max_readingdate = min(ReadingDate) from dbo.EMMR with(nolock)
where EMCo = @emco and Equipment = @equip and ReadingDate > @readingdate 
and [Source] = 'EMMeter'    and Miles <> 0

 --Get Last Odometer Reading from EMBF
select @embf_max_readingdate = min(MeterReadDate) from dbo.EMBF  
where Co = @emco and Mth = @mth and BatchId = @batchid and BatchSeq <> @seq and 
Equipment = @equip and MeterReadDate > @readingdate and [Source] = 'EMMeter' and MeterMiles <> 0

--Gets Next Meter Reading from either EMMR (history) or Current Batch
--If this variable has a value then a future meter reading exists.  
--If inserting or change a metering it's will value will effect the next previous meter reading'
if IsNull(@embf_max_readingdate,'') <> ''
begin
	if (isnull(@emmr_max_readingdate,'') <> '' and isnull(@emmr_max_readingdate,'') = IsNull(@embf_max_readingdate,'') and isnull(@batchtranstype,'') in( 'C','D'))
	or (isnull(@emmr_max_readingdate,'') = '' and isnull(@batchtranstype,'') = 'A' )
	begin
		if isnull(@deletetriggerYN,'') = 'Y' and isnull(@batchtranstype,'') = 'A' 
		begin 
			 --Get Last Odometer Reading from EMBF 
			select @embf_min_readingdate = max(MeterReadDate) from dbo.EMBF 
			where Co = @emco and Mth = @mth and BatchId = @batchid and Equipment = @equip and MeterReadDate <@readingdate 
			and [Source] = 'EMMeter'  and MeterMiles <> 0
			
			if isnull(@emmr_min_readingdate,'') <> ''
			begin
				/* the most recent meter reading from the current batch */
				select @embf_min_seq = max(BatchSeq)	from dbo.EMBF with(nolock)
				where Co = @emco and Mth = @mth and BatchId = @batchid and BatchSeq <> @seq 
				and Equipment = @equip and MeterReadDate = @embf_min_readingdate and [Source] = 'EMMeter'    and MeterMiles <> 0
				
				select  @currentodometer =CurrentOdometer
				from dbo.EMBF  with(nolock)
				where Co = @emco and Mth = @mth and BatchId = @batchid  and BatchSeq <> @seq and BatchSeq =@embf_min_seq 
				and Equipment = @equip and MeterReadDate = @embf_min_readingdate and Source = 'EMMeter'    and MeterMiles <> 0
			end
		end 
		/* the next meter reading from the current batch */
		select @embf_max_seq = min(BatchSeq)	from dbo.EMBF with(nolock)
		where Co = @emco and Mth = @mth and BatchId = @batchid and BatchSeq <> @seq 
		and Equipment = @equip and MeterReadDate = @embf_max_readingdate and [Source] = 'EMMeter'    and MeterMiles <> 0 
	
		update dbo.bEMBF
		set MeterMiles = CurrentOdometer-@currentodometer 
		where Co = @emco and Mth = @mth and BatchId = @batchid  and BatchSeq <> @seq and BatchSeq= @embf_max_seq 
		and Equipment = @equip and MeterReadDate = @embf_max_readingdate and Source = 'EMMeter'    and MeterMiles <> 0			
	end
end
/*END ODOMETER READING HISTORY EMMR/EMBF*/





bspexit:
 
return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspEMBFUpdateNextBatchSeq] TO [public]
GO
