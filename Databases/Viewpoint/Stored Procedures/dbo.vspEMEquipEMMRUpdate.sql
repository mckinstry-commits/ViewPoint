SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspEMEquipEMMRUpdate]  
/***********************************************************
* CREATED BY:   TRL 03/2010 - Issue 132064
* MODIFIED By : GF 10/02/2010 - issue #141031 changed to use vfDateOnly function
*
*
* USAGE:   This procedure creates a "EMEM Update'' reocrd in table EMMR
* when Meter readings or dates changed.  The goal is to create minimal amount
*of update records depending on what information is changed.
*	
* INPUT PARAMETERS
*	@emco		EM Company
*	@equip		Equipment to be validated
*	@hourreading 			HourReading
*	@hourdate 				HourDate
*	@replacedhourreading	ReplacedHourReading
*	@replacedhourreadingDate	ReplacedHourReadingDate
*	@odoreading 			OdoReading
*	@ododate 				OdoDate
*	@replacedodoreading	    ReplacedOdoReading
*	@replacedodoreading	    ReplacedOdoReadingDate
*
* OUTPUT PARAMETERS
*	ret val					EMEM column
*	@msg					Description or Error msg if error
**********************************************************/
(@emco bCompany = null, @equip bEquip = null ,@hourreading bHrs = null,@hourdate 	bDate = null,@hourdateYN 	bYN = null, 
@replacedhourreading	bHrs=null,@replacedhourdate bDate =null,@replacedhourdateYN bYN =null,@hourmeterschangedYN bYN = null, 
@odoreading bHrs = null,@ododate bDate = null ,@ododateYN bYN = null ,@replacedodoreading bHrs = null,
@replacedododate bDate = null,@replacedododateYN bYN = null,@odometerschangedYN bYN = null, @errmsg varchar(256) output)

as 

set nocount on

declare @rcode int,  @trans int, @mth bMonth, @readingdate1 bDate,@readingdate2 bDate,@readingdate3 bDate,@readingdate4 bDate 

select @rcode = 0

if @emco is null
begin
	select @errmsg = 'Missing EM Company!', @rcode = 1
	goto vspexit
end

if isnull(@equip,'')=''
begin
	select @errmsg = 'Missing Equipment!', @rcode = 1
	goto vspexit
end

--Set default mth for source in EMMR
select @mth = convert(smalldatetime,convert(varchar(2),Month(getdate())) + '/01/' + convert(varchar(4),year(getdate()))),
@readingdate1='',@readingdate2='',@readingdate3='',@readingdate4 =''

/*HOURS*/
if @hourdateYN='N'  and @hourdateYN='N'  or @hourmeterschangedYN='Y'
BEGIN
----#141031
	select @readingdate1 =  dbo.vfDateOnly()
end

if @hourdateYN='Y'  and @replacedhourdateYN='N' 
begin
	select @readingdate1 = @hourdate
end

if @hourdateYN='N'  and @replacedhourdateYN='Y' 
begin
	select @readingdate1 = @replacedhourdate
end

if @hourdateYN='Y'  and @hourdateYN='Y' 
begin
	if @hourdate <> @replacedhourdate
		begin
			select @readingdate1 = @hourdate
			select @readingdate2 = @replacedhourdate
		end
	else
		begin
			select @readingdate1 =@hourdate
		end
end

/*ODOMETER*/
if  @ododateYN='N' and @replacedododateYN= 'N'  or @odometerschangedYN='Y'
BEGIN
----#141031
	select @readingdate3 = isnull(@readingdate1, dbo.vfDateOnly())
end

if  @ododateYN='Y' and @replacedododateYN= 'N'
begin
	select @readingdate3 = @ododate
end

if  @ododateYN='N' and @replacedododateYN= 'Y'
begin
	select @readingdate3 = @replacedododate 
end

if  @ododateYN='Y' and @replacedododateYN= 'Y'
begin
	if @ododate <> @replacedododate
		begin
			select @readingdate3 = @ododate
			select @readingdate4 = @replacedododate
		end
	else
		begin
			select @readingdate3 = @ododate
		end
end

InsertEMMRrecord:
--Only Meter Readings Changed or 
--Hour and/or Replaced Hour Meter Dates Changed

if isnull(@readingdate1,'') = isnull(@readingdate3,'')
	begin 
		--All Meter Changes have the same date
		exec @trans = dbo.bspHQTCNextTrans 'bEMMR', @emco, @mth, @errmsg output
		if @trans = 0
		begin
			select @rcode = 1
			goto vspexit 
		end
		/* Make insertion into bEMMR */
		insert into bEMMR (EMCo, Mth, EMTrans, BatchId, Equipment, PostingDate, ReadingDate, Source,
		PreviousHourMeter,PreviousTotalHourMeter, CurrentHourMeter, CurrentTotalHourMeter, Hours, 
		PreviousOdometer, PreviousTotalOdometer,  CurrentOdometer, CurrentTotalOdometer, Miles, 
		InUseBatchID)
		----#141031
		select @emco, @mth, @trans,null,@equip, dbo.vfDateOnly(), isnull(@readingdate1, dbo.vfDateOnly()),'EMEMUpdate' ,
		0,0,@hourreading,@replacedhourreading,0,
		0,0,@odoreading, @replacedodoreading,0,
		null
	end 
else

begin 
	--Record only Meter Reading Changes
	--Record only Hour Meter Reading Changes
	 if isnull(@readingdate1,'') <>''
	begin 
		--All Meter Changes have the same date
		exec @trans = dbo.bspHQTCNextTrans 'bEMMR', @emco, @mth, @errmsg output
		if @trans = 0
		begin
			select @rcode = 1
			goto vspexit 
		end
		/* Make insertion into bEMMR */
		insert into bEMMR (EMCo, Mth, EMTrans, BatchId, Equipment, PostingDate, ReadingDate, Source,
		PreviousHourMeter,PreviousTotalHourMeter, CurrentHourMeter, CurrentTotalHourMeter, Hours, 
		PreviousOdometer, PreviousTotalOdometer,  CurrentOdometer, CurrentTotalOdometer, Miles, 
		InUseBatchID)
		----#141031
		select  @emco, @mth, @trans,null,@equip, dbo.vfDateOnly(), @readingdate1,'EMEMUpdate' ,
		0,0,@hourreading,@replacedhourreading,0,
		0,0,@odoreading, @replacedodoreading,0,
		null
	end 
	--Record Odometer Date Change
	if isnull(@readingdate3,'') <>''
	begin 
			--All Meter Changes have the same date
		exec @trans = dbo.bspHQTCNextTrans 'bEMMR', @emco, @mth, @errmsg output
		if @trans = 0
		begin
			select @rcode = 1
			goto vspexit 
		end
		/* Make insertion into bEMMR */
		insert into bEMMR (EMCo, Mth, EMTrans, BatchId, Equipment, PostingDate, ReadingDate, Source,
		PreviousHourMeter,PreviousTotalHourMeter, CurrentHourMeter, CurrentTotalHourMeter, Hours, 
		PreviousOdometer, PreviousTotalOdometer,  CurrentOdometer, CurrentTotalOdometer, Miles, 
		InUseBatchID)
		----#141031
		select  @emco, @mth, @trans,null,@equip, dbo.vfDateOnly(), @readingdate3,'EMEMUpdate' ,
		0,0,@hourreading,@replacedhourreading,0,
		0,0,@odoreading, @replacedodoreading,0,
		null
	end 
	--Record Replaced HourMeter Date change
	if isnull(@readingdate2,'') <>''
	begin 
		--All Meter Changes have the same date
		exec @trans = dbo.bspHQTCNextTrans 'bEMMR', @emco, @mth, @errmsg output
		if @trans = 0
		begin
			select @rcode = 1
			goto vspexit 
		end
		/* Make insertion into bEMMR */
		insert into bEMMR (EMCo, Mth, EMTrans, BatchId, Equipment, PostingDate, ReadingDate, Source,
		PreviousHourMeter,PreviousTotalHourMeter, CurrentHourMeter, CurrentTotalHourMeter, Hours, 
		PreviousOdometer, PreviousTotalOdometer,  CurrentOdometer, CurrentTotalOdometer, Miles, 
		InUseBatchID)
		----#141031
		select  @emco, @mth, @trans,null,@equip, dbo.vfDateOnly(), @readingdate2,'EMEMUpdate' ,
		0,0,@hourreading,@replacedhourreading,0,
		0,0,@odoreading, @replacedodoreading,0,
		null
	end 
	--Record Replaced Odometer Date change
	if isnull(@readingdate4,'') <>''
	begin 
		--All Meter Changes have the same date
		exec @trans = dbo.bspHQTCNextTrans 'bEMMR', @emco, @mth, @errmsg output
		if @trans = 0
		begin
			select @rcode = 1
			goto vspexit 
		end
		/* Make insertion into bEMMR */
		insert into bEMMR (EMCo, Mth, EMTrans, BatchId, Equipment, PostingDate, ReadingDate, Source,
		PreviousHourMeter,PreviousTotalHourMeter, CurrentHourMeter, CurrentTotalHourMeter, Hours, 
		PreviousOdometer, PreviousTotalOdometer,  CurrentOdometer, CurrentTotalOdometer, Miles, 
		InUseBatchID)
		----#141031
		select  @emco, @mth, @trans,null,@equip, dbo.vfDateOnly(), @readingdate4,'EMEMUpdate' ,
		0,0,@hourreading,@replacedhourreading,0,
		0,0,@odoreading, @replacedodoreading,0,
		null
	end 
end 

vspexit:

return @rcode

			


		
      		


GO
GRANT EXECUTE ON  [dbo].[vspEMEquipEMMRUpdate] TO [public]
GO
