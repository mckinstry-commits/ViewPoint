SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspEMMRUpdateNextReading]  
/***********************************************************
* CREATED BY:  TRL 02/09/2010 Issue 132064
* MODIFIED By :
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
(@emco bCompany = null, @deletetriggerYN bYN = null, @equip bEquip = null,@readingdate bDate = null,
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
--Get Next Odometer Reading EMMR
select @emmr_max_readingdate = min(ReadingDate) from dbo.EMMR with(nolock)
where EMCo = @emco and Equipment = @equip and ReadingDate > @readingdate 
and [Source] = 'EMMeter'    and [Hours] <> 0

if isnull(@emmr_max_readingdate,'') <> ''
begin
		if isnull(@deletetriggerYN,'') = 'Y'
		begin 
			select @emmr_min_readingdate = max(ReadingDate) from dbo.EMMR with(nolock)
			where EMCo = @emco and Equipment = @equip and ReadingDate < @readingdate 
			and [Source] = 'EMMeter'  and [Hours] <> 0 
			
			if isnull(@emmr_min_readingdate,'') <> ''
			begin
				/* the most recent month from the most recent prior transfer */
				select @emmr_min_mth = max(Mth) from dbo.EMMR with(nolock)
				where EMCo = @emco and Equipment = @equip and ReadingDate = @emmr_min_readingdate 
				and [Source] = 'EMMeter'   and [Hours] <> 0

				/* the most recent transaction from the most recent prior transfer */
				select @emmr_min_trans = max(EMTrans)	from dbo.EMMR with(nolock)
				where EMCo = @emco and Equipment = @equip and Mth = @emmr_min_mth and ReadingDate = @emmr_min_readingdate 
				and [Source] = 'EMMeter'   and [Hours] <> 0
				
				select  @currenthourmeter =CurrentHourMeter 
				from dbo.EMMR  with(nolock)
				where EMCo = @emco and Equipment = @equip and Mth = @emmr_min_mth and EMTrans = @emmr_min_trans
				and Source = 'EMMeter'   and [Hours] <> 0
			end
		end 

	/* the most recent month from the most recent prior transfer */
	select @emmr_max_mth = min(Mth) from dbo.EMMR with(nolock)
	where EMCo = @emco and Equipment = @equip and ReadingDate = @emmr_max_readingdate
	and [Source] = 'EMMeter'  and [Hours] <> 0

	/* the most recent transaction from the most recent prior transfer */
	select @emmr_max_trans = min(EMTrans)	from dbo.EMMR with(nolock)
	where EMCo = @emco and Equipment = @equip and Mth = @emmr_max_mth and ReadingDate = @emmr_max_readingdate  
	and [Source] = 'EMMeter'  and [Hours] <> 0
	
	update dbo.EMMR   
	set Hours = CurrentHourMeter-@currenthourmeter
	where  EMCo = @emco and Equipment =@equip and Mth = @emmr_max_mth and EMTrans = @emmr_max_trans
	and [Source] = 'EMMeter'  and [Hours] <> 0
	
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

--Gets Next Meter Reading from either EMMR (history) or Current Batch
if isnull(@emmr_max_readingdate,'') <> ''
begin
		if isnull(@deletetriggerYN,'') = 'Y'
		begin 
			select @emmr_min_readingdate = max(ReadingDate) from dbo.EMMR with(nolock)
			where EMCo = @emco and Equipment = @equip and ReadingDate < @readingdate 
			and [Source] = 'EMMeter'  and Miles <> 0
			
			if isnull(@emmr_min_readingdate,'') <> ''
			begin
				/* the most recent month from the most recent prior transfer */
				select @emmr_min_mth = max(Mth) from dbo.EMMR with(nolock)
				where EMCo = @emco and Equipment = @equip and ReadingDate = @emmr_min_readingdate 
				and [Source] = 'EMMeter'   and Miles <> 0

				/* the most recent transaction from the most recent prior transfer */
				select @emmr_min_trans = max(EMTrans)	from dbo.EMMR with(nolock)
				where EMCo = @emco and Equipment = @equip and Mth = @emmr_min_mth and ReadingDate = @emmr_min_readingdate 
				and [Source] = 'EMMeter'   and Miles <> 0
				
				select  @currentodometer =CurrentOdometer
				from dbo.EMMR  with(nolock)
				where EMCo = @emco and Equipment = @equip and Mth = @emmr_min_mth and EMTrans = @emmr_min_trans
				and Source = 'EMMeter'   and Miles <> 0
			end
		end 

		/* the most recent month from the most recent prior transfer */
		select @emmr_max_mth = min(Mth) from dbo.EMMR with(nolock)
		where EMCo = @emco and Equipment = @equip and ReadingDate = @emmr_max_readingdate
		and [Source] = 'EMMeter'   and Miles <> 0

		/* the most recent transaction from the most recent prior transfer */
		select @emmr_max_trans = min(EMTrans)	from dbo.EMMR with(nolock)
		where EMCo = @emco and Equipment = @equip and Mth = @emmr_max_mth and ReadingDate = @emmr_max_readingdate  
		and [Source] = 'EMMeter'   and Miles <> 0
	
		update dbo.EMMR 
		set Miles = CurrentOdometer-@currentodometer
		where EMCo = @emco and Equipment =@equip and Mth = @emmr_max_mth and EMTrans = @emmr_max_trans
		and [Source] = 'EMMeter'   and Miles <> 0
	
end
/*END ODOMETER READING HISTORY EMMR/EMBF*/

bspexit:
 
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMMRUpdateNextReading] TO [public]
GO
