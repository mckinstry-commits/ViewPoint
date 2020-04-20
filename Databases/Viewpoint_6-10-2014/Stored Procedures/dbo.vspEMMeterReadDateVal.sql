SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspEMMeterReadDateVal]
/***********************************************************
* CREATED BY: 
* MODIFIED By :
*
* USAGE:
*	Validates EMEM.Equipment and returns necessary HourMeter and
*	Odometer info.
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
(/*-1*/@emco bCompany = null, /*40*/@equip bEquip = null, /*20*/@emtrans bTrans = null, /*0*/@mth bMonth = null,
/*1*/@batchid bBatchID, /*2*/@batchseq int=null,/*10*/@batchtranstype varchar(1)=null,/*30*/@readingdate bDate = null,
@msg varchar(255) output)

as

set nocount on

declare @rcode int, @status char(1), @numrows smallint, @type char(1),
@error_existing_day varchar (12),@error_existing_month varchar (10)
 
select @rcode = 0

if @emco is null
begin
	select @msg = 'Missing EM Company!', @rcode = 1
	goto bspexit
end

if isnull(@equip,'')='' and @emtrans is not null 
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

if @equip <> ''
begin 
	-- Reject if Equip is in any current batch other than its own 
	--This works for Equip when it exists in a different Batch Month
	if exists(select * from dbo.EMBF with(nolock)where Co = @emco and Source = 'EMMeter' and Equipment = @equip and (BatchId<>@batchid and Mth<>@mth))
	begin
		select @msg = 'Equipment present in active batch - cannot add until all open batches posted!', @rcode = 1
		goto bspexit
	end
	--This work for Equip when it exists in other batches in the same batch month
	if exists(select * from dbo.EMBF with(nolock)where Co = @emco and Source = 'EMMeter' and Equipment = @equip and BatchId<>@batchid and Mth=@mth)
	begin
		select @msg = 'Equipment present in active batch - cannot add until all open batches posted!', @rcode = 1
		goto bspexit
	end
	--Error when Equipment has duplicate Meter Reading  dates in current batch
	--for new records
	
	if isnull(@batchtranstype,'') = 'A' and @emtrans is  null
	begin 
		if exists(select * from dbo.EMBF with(nolock) where Co = @emco and BatchId=@batchid and Mth=@mth and BatchSeq<> @batchseq
		and BatchTransType in ( 'A','C','D') and Source = 'EMMeter' and Equipment = @equip and MeterReadDate = @readingdate)
		begin 
			select @msg = 'Equipment already has a  Meter Reading in the current batch!' , @rcode = 1
			goto bspexit
		end
		--Only one meter reading per Equipment per Reading Date
		if  exists (select * from dbo.EMMR with(nolock) where EMCo = @emco and Equipment = @equip and ReadingDate = @readingdate 	and [Source] = 'EMMeter' ) 
		begin 
			select @error_existing_day =convert(varchar,month(r.ReadingDate))+'/'+convert(varchar,day(r.ReadingDate))+'/'+convert(varchar,Year(r.ReadingDate)),
			@error_existing_month =convert(varchar,month(r.Mth))+'/' +convert(varchar,Year(r.Mth)) 
			 from dbo.EMMR r with(nolock) 
			 where r.EMCo = @emco and r.Equipment = @equip and r.ReadingDate = @readingdate and r.Source = 'EMMeter' 
			 
			select @msg = 'Equipment already has a Meter Reading recorded for '+@error_existing_day + ' in month: ' +@error_existing_month+ '!', @rcode = 1
			goto bspexit
		end  
	end
end 

bspexit:
 
return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspEMMeterReadDateVal] TO [public]
GO
