SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspEMEquipValForMeterReadings]
/***********************************************************
* CREATED BY:  TRL 03/2010 - Issue 132064
* MODIFIED By :
*
* USAGE:
*	Validates MeterReading date and Equipment in EM Meter Readings
*
* INPUT PARAMETERS
*	@emco		EM Company
*	@equip		Equipment to be validated
* @emtrans    If null, indicates return of Hour/Odo info from bEMEM;
*              If not null, indicates return of same from bEMMR by @emco/@mth/@emtrans.
* @mth        Batch Month.
* @readingdate Reading date from form.
*
* OUTPUT PARAMETERS
*	ret val					EMEM column
*	-------					-----------
*	@odoreading 			OdoReading
*	@ododate 				OdoDate
*	@replacedodoreading	    ReplacedOdoReading
* @previoustotalodometer  ReplacedOdoReading + OdoReading
*	@hourreading 			HourReading
*	@hourdate 				HourDate
*	@replacedhourreading	ReplacedHourReading
* @previoustotalhourmeter ReplacedHourReading + HourReading
*	@msg					Description or Error msg if error
**********************************************************/
(/*-1*/@emco bCompany = null, /*40*/@equip bEquip = null, /*20*/@emtrans bTrans = null, 
/*0*/@mth bMonth = null,/*1*/@batchid bBatchID, /*2*/@batchseq int=null,/*10*/@batchtranstype varchar(1)=null,/*30*/@readingdate bDate = null,
/*180*/@equip_replacedodoreading bHrs = null output,
/*181*/@equip_replacedododate bDate =null output ,
/*190*/@previoustotalodometer bHrs = null output,
/*150*/@equip_replacedhourreading bHrs = null output, 
/*151*/@equip_replacedhourdate bDate = null output,
/*160*/@previoustotalhourmeter bHrs = null output,
/*Form Label 100*/@equip_odoreading bHrs = null output,
 /*Form Label 90*/@equip_ododate bDate = null output, 
/*Form Label 300*/@lastododate bDate=null output, 
/*Form Label 305*/@lastodometer bHrs =null output,
/*310*/@last_total_odometer bHrs=null output,
/*Form Label 315*/@nextododate bDate=null output, 
/*Form Label320*/@nextodometer bHrs =null output,
/*325*/@next_total_odometer bHrs=null output,
/*Form Label 400*/@lastusageodosource bSource =null output,
/*Form Label 405*/@lastusageododate bDate =null output,
/*Form Label 410*/ @lastusageodometer bHrs =null output, 
/*Form Label 60*/@equip_hourreading bHrs = null output, 
/*Form Label 50*/@equip_hourdate bDate = null output, 
/*Form Label 350*/@lasthourdate bDate=null output, 
/*Form Label 355*/@lasthourmeter bHrs =null output, 
/*360*/@lasthourmetertotal bHrs=null output,
/*Form Label 365*/@nexthourdate bDate=null output, 
/*Form Label 370*/@nexthourmeter bHrs =null output,
/*375*/@nexthourmetertotal bHrs=null output,
/*Form Label 450*/@lastusagehoursource bSource =null output, 
/*Form Label 455*/@lastusagehourdate bDate =null output, 
/*Form Label 460*/@lastusagehourmeter bHrs =null output, 
@msg varchar(255) output)

as

set nocount on

declare @rcode int, @status char(1), @numrows smallint, @type char(1),
/*Variables used to get last and next Odo/Hours meter readings for the Meter Reading Date @readingdate*/
@emmr_min_readingdate bDate, @emmr_min_mth bMonth, @emmr_min_trans bTrans, 
@embf_min_readingdate bDate, @embf_min_seq int, 
@emmr_max_readingdate bDate, @emmr_max_mth bMonth, @emmr_max_trans bTrans, 
@embf_max_readingdate bDate,@embf_max_seq int ,

@error_existing_day varchar (12),@error_existing_month varchar (10)
 
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
	select @msg = 'Reading Date cannot exceed the Batch Month!', @rcode = 1
	goto bspexit
end

--Return if Equipment Change in progress for New Equipment Code
exec @rcode = vspEMEquipChangeInProgressVal @emco, @equip, @msg output
If @rcode = 1
	begin
	goto bspexit
end

-- Reject if Equip is in any current batch other than its own 
--This works for Equip when it exists in a different Batch Month
if exists(select * from dbo.EMBF with(nolock)where Co = @emco and Source = 'EMMeter' and Equipment = @equip and (BatchId<>@batchid and Mth<>@mth))
begin
	select @msg = 'Equipment exists in another Open batch - cannot add record!', @rcode = 1
	goto bspexit
end
 --This work for Equip when it exists in other batches in the same batch month
if exists(select * from dbo.EMBF with(nolock)where Co = @emco and Source = 'EMMeter' and Equipment = @equip and BatchId<>@batchid and Mth=@mth)
begin
	select @msg = 'Equipment exists in another Open batch - cannot add record!', @rcode = 1
	goto bspexit
end

-- Get all info from bEMEM, assuming that @emtrans is null and Hour/Odo info will come from bEMEM. 
select  @equip_odoreading=OdoReading, @equip_ododate=OdoDate, @equip_replacedodoreading=ReplacedOdoReading,
@equip_hourreading=HourReading, @equip_hourdate=HourDate, @equip_replacedhourreading=ReplacedHourReading,
@status = Status, @type = [Type],@msg=Description,
@equip_replacedododate =ReplacedOdoDate , @equip_replacedhourdate = ReplacedHourDate 

from dbo.EMEM with(nolock)
where EMCo = @emco and Equipment = @equip
if @@rowcount = 0
begin
	select @msg = 'Equipment invalid!', @rcode = 1
	goto bspexit
end

-- Do not allow posting of meters directly to a component 
if @type = 'C'
begin
	select @msg = 'Do not post meters directly to Component!', @rcode = 1
	goto bspexit
end

-- Reject if Status inactive. 
if @status = 'I'
begin
	select @msg = 'Equipment Status = Inactive!', @rcode = 1
	goto bspexit
end

--Error when Equipment has duplicate Meter Reading  dates in current batch
--for new records
if isnull(@batchtranstype,'') = 'A' and @emtrans is  null
begin 
	if exists(select * from dbo.EMBF with(nolock) where Co = @emco and BatchId=@batchid and Mth=@mth and BatchSeq<> @batchseq
	and BatchTransType in ( 'A','C','D') and Source = 'EMMeter' and Equipment = @equip and MeterReadDate = @readingdate)
	begin 
		select @msg = 'Equipment already has a Meter reading for this Reading Date in the current batch!' , @rcode = 1
		goto bspexit
	end
	--Only one meter reading per Equipment per Reading Date
	if  exists (select * from dbo.EMMR with(nolock) where EMCo = @emco and Equipment = @equip and ReadingDate = @readingdate 	and [Source] = 'EMMeter' ) 
	begin 
		select @error_existing_day =convert(varchar,month(r.ReadingDate))+'/'+convert(varchar,day(r.ReadingDate))+'/'+convert(varchar,Year(r.ReadingDate)),
		@error_existing_month =convert(varchar,month(r.Mth))+'/' +convert(varchar,Year(r.Mth))
		 from dbo.EMMR r with(nolock) 
		 where r.EMCo = @emco and r.Equipment = @equip and r.ReadingDate = @readingdate and r.Source = 'EMMeter' 
		select @msg = 'Equipment already has a Meter reading recorded on '+@error_existing_day + ' in month: ' +@error_existing_month+ '!', @rcode = 1
		goto bspexit
	end  
end
	
-- If @emtrans type is not null and trans type 'C'hange or 'D'elete, 
--so replace Hour/Odo info just pulled from EMEM from EMMR. 
if (isnull(@batchtranstype,'') = 'C' or isnull(@batchtranstype,'') ='D') and @emtrans is not null
begin 
	select --@equip_odoreading = CurrentOdometer-Miles, @equip_hourreading = CurrentHourMeter---Hours,
	@equip_replacedodoreading = CurrentTotalOdometer-CurrentOdometer,---Miles, 
	@equip_replacedhourreading = CurrentTotalHourMeter-CurrentHourMeter---Hours
	from dbo.EMMR with(nolock)
	where EMCo = @emco and Mth = @mth and EMTrans = @emtrans
end


/*Get Last Usage Odometer reading*/
select @lastusageododate = max(ReadingDate) from dbo.EMMR with(nolock) 
where EMCo=@emco and Equipment=@equip and Source in('MS','PR','EMRev') and Miles > 0

select @lastusageodosource = [Source], @lastusageodometer=CurrentOdometer 
from dbo.EMMR with(nolock)
where EMCo=@emco and Equipment=@equip and Source in('MS','PR','EMRev') and ReadingDate=@lastusageododate and Miles > 0
 
/*Get Last Usage Hour Meter reading*/ 
select @lastusagehourdate = max(ReadingDate) from dbo.EMMR with(nolock) 
where EMCo=@emco and Equipment=@equip and Source in('MS','PR','EMRev') and [Hours] > 0 

select @lastusagehoursource = [Source], @lastusagehourmeter=CurrentHourMeter
from dbo.EMMR with(nolock) 
where EMCo=@emco and Equipment=@equip and Source in('MS','PR','EMRev') and ReadingDate=@lastusagehourdate and [Hours] > 0 


	
-- Calculate previous total odo/hour meters. 
select @previoustotalodometer = @equip_odoreading + @equip_replacedodoreading,
@previoustotalhourmeter = @equip_hourreading+ @equip_replacedhourreading 	

--Set variables 
select @emmr_min_readingdate=null, @emmr_min_mth=null, @emmr_min_trans =null, 
@embf_min_readingdate =null, @embf_min_seq =null, 
@emmr_max_readingdate =null, @emmr_max_mth =null, @emmr_max_trans =null, 
@embf_max_readingdate =null,@embf_max_seq = null 

/*START HOUR METER READING HISTORY EMMR/EMBF*/
--Get Last Hour Meter Reading from EMMR
 select @emmr_min_readingdate = max(ReadingDate) from dbo.EMMR r with(nolock)
Left join dbo.EMBF f with(nolock)on f.Co=r.EMCo and f.Equipment=r.Equipment  and f.MeterReadDate = r.ReadingDate  
where r.EMCo = @emco and r.Equipment = @equip and r.ReadingDate < @readingdate 
and r.Source = 'EMMeter' 
and r.InUseBatchID is null 
and isnull(f.BatchTransType,'X') <> 'D' 
and isnull(f.Mth,@mth) = @mth and isnull(f.BatchId,@batchid) = @batchid  

 --Get Last Hour Meter Reading from EMBF
select @embf_min_readingdate = max(MeterReadDate) from dbo.EMBF 
where Co = @emco and Mth = @mth and BatchId = @batchid and BatchSeq <> @batchseq 
and Equipment = @equip and MeterReadDate <@readingdate and [Source] = 'EMMeter'  
and BatchTransType <> 'D'

if (isnull(@emmr_min_readingdate,'') <> '' and isnull(@embf_min_readingdate,'') = '')
or (isnull(@emmr_min_readingdate,'') > isnull(@embf_min_readingdate,'') and isnull(@embf_min_readingdate,'') <> '' )
	begin 
		/* the most recent month from the most recent prior transfer */
		select @emmr_min_mth = max(Mth) from dbo.EMMR with(nolock)
		where EMCo = @emco and Equipment = @equip and ReadingDate = @emmr_min_readingdate 
		and [Source] = 'EMMeter'   

		/* the most recent transaction from the most recent prior transfer */
		select @emmr_min_trans = max(EMTrans)	from dbo.EMMR with(nolock)
		where EMCo = @emco and Equipment = @equip and Mth = @emmr_min_mth and ReadingDate = @emmr_min_readingdate 
		and [Source] = 'EMMeter'   

		select  @lasthourdate=@emmr_min_readingdate, @lasthourmeter=CurrentHourMeter, @lasthourmetertotal = CurrentTotalHourMeter
		from dbo.EMMR  with(nolock)
		where EMCo = @emco and Equipment = @equip and Mth = @emmr_min_mth and EMTrans = @emmr_min_trans
		and Source = 'EMMeter' 
			end
else
	begin
		/* the most recent transaction from the most recent prior transfer */
		select @embf_min_seq = max(BatchSeq)	from dbo.EMBF with(nolock)
		where Co = @emco and Mth = @mth and BatchId = @batchid  and BatchSeq <> @batchseq 
		and Equipment = @equip and MeterReadDate = @embf_min_readingdate and [Source] = 'EMMeter'  
	
		select  @lasthourdate=@embf_min_readingdate, @lasthourmeter=CurrentHourMeter, @lasthourmetertotal = CurrentTotalHourMeter 
		from dbo.EMBF  with(nolock)
		where Co = @emco and Mth = @mth and BatchId = @batchid  and BatchSeq <> @batchseq  and BatchSeq = @embf_min_seq 
		and Equipment = @equip and MeterReadDate = @embf_min_readingdate and Source = 'EMMeter'   
	end
	
----Replaced Meter Readings are subject to retro meter readings, current total meter readings shouldn't include replaced meter
--if isnull(@lasthourdate,'') <= isnull(@equip_replacedhourdate,'12/31/2049')
--begin
--	select @equip_replacedhourreading = @lasthourmetertotal - @lasthourmeter 
--end
		
--Get Next Hour Meter Reading (EMMR/EMBF)
select @emmr_max_readingdate = min(r.ReadingDate) from dbo.EMMR r with(nolock)
Left join dbo.EMBF f with(nolock)on f.Co=r.EMCo and f.Equipment=r.Equipment  and f.MeterReadDate = r.ReadingDate 
where r.EMCo = @emco and r.Equipment = @equip and r.ReadingDate > @readingdate 
and r.Source = 'EMMeter'   
and r.InUseBatchID is null 
and isnull(f.BatchTransType,'X') <> 'D' 
and isnull(f.Mth,@mth) = @mth and isnull(f.BatchId,@batchid) = @batchid  

 --Get Next Hour Meter Reading from EMBF
select @embf_max_readingdate = min(MeterReadDate) from dbo.EMBF  
where Co = @emco and Mth = @mth and BatchId = @batchid  and BatchSeq <> @batchseq 
and Equipment = @equip and MeterReadDate > @readingdate and [Source] = 'EMMeter' 
and BatchTransType <> 'D'


if (isnull(@emmr_max_readingdate,'') = '' and IsNull(@embf_max_readingdate,'') >= @readingdate )
or (isnull(@emmr_max_readingdate,'') >= @readingdate and IsNull(@embf_max_readingdate,'') >= @readingdate 
	and isnull(@emmr_max_readingdate,'') >= IsNull(@embf_max_readingdate,'') )
	begin
		/* the most recent transaction from the most recent prior transfer */
			select @embf_max_seq = min(BatchSeq)	from dbo.EMBF with(nolock)
			where Co = @emco and Mth = @mth and BatchId = @batchid  and BatchSeq <> @batchseq 
			and Equipment = @equip and MeterReadDate = @embf_max_readingdate and [Source] = 'EMMeter'   
		
			select  @nexthourdate=@embf_max_readingdate, @nexthourmeter=CurrentHourMeter, @nexthourmetertotal = CurrentTotalHourMeter
			from dbo.EMBF  with(nolock)
			where Co = @emco and Mth = @mth and BatchId = @batchid   and BatchSeq <> @batchseq and BatchSeq = @embf_max_seq 
			and Equipment = @equip and MeterReadDate = @embf_max_readingdate 	and Source = 'EMMeter'  
	end
else	
	begin 
		if isnull(@emmr_max_readingdate,'') > IsNull(@embf_max_readingdate,'') and  IsNull(@embf_max_readingdate,'')  <> ''
		BEGIN
			select @emmr_max_readingdate=@embf_max_readingdate
		end
		/* the most recent month from the most recent prior transfer */
		select @emmr_max_mth = min(Mth) from dbo.EMMR with(nolock)
		where EMCo = @emco and Equipment = @equip and ReadingDate = @emmr_max_readingdate
		and [Source] = 'EMMeter'  

		/* the most recent transaction from the most recent prior transfer */
		select @emmr_max_trans = min(EMTrans)	from dbo.EMMR with(nolock)
		where EMCo = @emco and Equipment = @equip and Mth = @emmr_max_mth and ReadingDate = @emmr_max_readingdate  
		and [Source] = 'EMMeter'  
			
		select @nexthourdate=@emmr_max_readingdate, @nexthourmeter=CurrentHourMeter, @nexthourmetertotal = CurrentTotalHourMeter
		from dbo.EMMR with(nolock)
		where EMCo = @emco and Equipment =@equip and Mth = @emmr_max_mth and EMTrans = @emmr_max_trans
		and [Source] = 'EMMeter'  
	
	end

	
/*END HOUR METER READING HISTORY EMMR/EMBF*/

--Reset variables 
select @emmr_min_readingdate=null, @emmr_min_mth=null, @emmr_min_trans =null, 
@embf_min_readingdate =null, @embf_min_seq =null, 
@emmr_max_readingdate =null, @emmr_max_mth =null, @emmr_max_trans =null, 
@embf_max_readingdate =null,@embf_max_seq = null 

/*START ODOMETER READING HISTORY EMMR/EMBF*/
--To Account for consecutive meter reading dates
--Get Last Odometer Reading from EMMR 
 select @emmr_min_readingdate = max(ReadingDate) from dbo.EMMR r with(nolock)
Left join dbo.EMBF f with(nolock)on f.Co=r.EMCo and f.Equipment=r.Equipment  and f.MeterReadDate = r.ReadingDate  
where r.EMCo = @emco and r.Equipment = @equip and r.ReadingDate < @readingdate 
and r.Source = 'EMMeter'  
and r.InUseBatchID is null 
and isnull(f.BatchTransType,'X') <> 'D' 
and isnull(f.Mth,@mth) = @mth and isnull(f.BatchId,@batchid) = @batchid  

 --Get Last Odometer Reading from EMBF 
select @embf_min_readingdate = max(MeterReadDate) from dbo.EMBF 
where Co = @emco and Mth = @mth and BatchId = @batchid  and BatchSeq <> @batchseq 
and Equipment = @equip and MeterReadDate <@readingdate and [Source] = 'EMMeter'  
and BatchTransType <> 'D'

--Gets last Meter Reading from either EMMR (history) or Current Batch
if (isnull(@emmr_min_readingdate,'') <> '' and isnull(@embf_min_readingdate,'') = '')
or (isnull(@emmr_min_readingdate,'') > isnull(@embf_min_readingdate,'') and isnull(@embf_min_readingdate,'') <> '' )
	begin 
		/* the most recent month from the most recent prior transfer */
		select @emmr_min_mth = max(Mth) from dbo.EMMR with(nolock)
		where EMCo = @emco and Equipment = @equip and ReadingDate = @emmr_min_readingdate 
		and [Source] = 'EMMeter' 

		/* the most recent transaction from the most recent prior transfer */
		select @emmr_min_trans = max(EMTrans)	from dbo.EMMR with(nolock)
		where EMCo = @emco and Equipment = @equip and Mth = @emmr_min_mth and ReadingDate = @emmr_min_readingdate 
		and [Source] = 'EMMeter' 

		select  @lastododate=@emmr_min_readingdate, @lastodometer=CurrentOdometer, @last_total_odometer = CurrentTotalOdometer
		from dbo.EMMR  with(nolock)
		where EMCo = @emco and Equipment = @equip and Mth = @emmr_min_mth and EMTrans = @emmr_min_trans
		and Source = 'EMMeter'   
	end
else
	begin
		/* the most recent meter reading from the current batch */
		select @embf_min_seq = max(BatchSeq)	from dbo.EMBF with(nolock)
		where Co = @emco and Mth = @mth and BatchId = @batchid  and BatchSeq <> @batchseq 
		and Equipment = @equip and MeterReadDate = @embf_min_readingdate and [Source] = 'EMMeter'    
	
		select  @lastododate=@embf_min_readingdate, @lastodometer=CurrentOdometer, @last_total_odometer = CurrentTotalOdometer
		from dbo.EMBF  with(nolock)
		where Co = @emco and Mth = @mth and BatchId = @batchid   and BatchSeq <> @batchseq and BatchSeq =@embf_min_seq 
		and Equipment = @equip and MeterReadDate = @embf_min_readingdate and Source = 'EMMeter'    
	end
	
------Replaced Meter Readings are subject to retro meter readings, current total meter readings shouldn't include replaced meter
--if  isnull(@lastododate,'') <= isnull(@equip_replacedododate,'12/31/2049')
--begin
--	select @equip_replacedodoreading = @last_total_odometer - @lastodometer 
--end

--Get Next Odometer Reading (EMMR/EMBF)
select @emmr_max_readingdate = min(ReadingDate) from dbo.EMMR r with(nolock)
Left join dbo.EMBF f with(nolock)on f.Co=r.EMCo and f.Equipment=r.Equipment  and f.MeterReadDate = r.ReadingDate 
where r.EMCo = @emco and r.Equipment = @equip and r.ReadingDate > @readingdate 
and r.Source = 'EMMeter'  
and r.InUseBatchID is null 
and isnull(f.BatchTransType,'X') <> 'D' 
and isnull(f.Mth,@mth) = @mth and isnull(f.BatchId,@batchid) = @batchid  

 --Get Last Odometer Reading from EMBF
select @embf_max_readingdate = min(MeterReadDate) from dbo.EMBF  
where Co = @emco and Mth = @mth and BatchId = @batchid and  BatchSeq <> @batchseq 
and  Equipment = @equip and MeterReadDate > @readingdate and [Source] = 'EMMeter' 
and BatchTransType <> 'D'
--Gets Next Meter Reading from either EMMR (history) or Current Batch

if (isnull(@emmr_max_readingdate,'') = '' and IsNull(@embf_max_readingdate,'') >= @readingdate )
or (isnull(@emmr_max_readingdate,'') >= @readingdate and IsNull(@embf_max_readingdate,'') >= @readingdate 
	and isnull(@emmr_max_readingdate,'') >= IsNull(@embf_max_readingdate,'') )
	begin
		/* the next meter reading from the current batch */
		select @embf_max_seq = min(BatchSeq)	from dbo.EMBF with(nolock)
		where Co = @emco and Mth = @mth and BatchId = @batchid  and BatchSeq <> @batchseq 
		and Equipment = @equip and MeterReadDate = @embf_max_readingdate and [Source] = 'EMMeter'  
		
		select  @nextododate=@embf_max_readingdate, @nextodometer=CurrentOdometer, @next_total_odometer = CurrentTotalOdometer
		from dbo.EMBF  with(nolock)
		where Co = @emco and Mth = @mth and BatchId = @batchid   and BatchSeq <> @batchseq and BatchSeq= @embf_max_seq 
		and Equipment = @equip and MeterReadDate = @embf_max_readingdate and Source = 'EMMeter'    
	end
else	
	begin
		if isnull(@emmr_max_readingdate,'') > IsNull(@embf_max_readingdate,'') and  IsNull(@embf_max_readingdate,'')<>'' 
		BEGIN
			select @emmr_max_readingdate= @embf_max_readingdate
		END
			/* the most recent month from the most recent prior transfer */
			select @emmr_max_mth = min(Mth) from dbo.EMMR with(nolock)
			where EMCo = @emco and Equipment = @equip and ReadingDate = @emmr_max_readingdate
			and [Source] = 'EMMeter'   

			/* the most recent transaction from the most recent prior transfer */
			select @emmr_max_trans = min(EMTrans)	from dbo.EMMR with(nolock)
			where EMCo = @emco and Equipment = @equip and Mth = @emmr_max_mth and ReadingDate = @emmr_max_readingdate  
			and [Source] = 'EMMeter'   
				
			select @nextododate=@emmr_max_readingdate, @nextodometer=CurrentOdometer, @next_total_odometer = CurrentTotalOdometer
			from dbo.EMMR with(nolock)
			where EMCo = @emco and Equipment =@equip and Mth = @emmr_max_mth and EMTrans = @emmr_max_trans
			and [Source] = 'EMMeter'   
		
	end
/*END ODOMETER READING HISTORY EMMR/EMBF*/

bspexit:
 
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMEquipValForMeterReadings] TO [public]
GO
