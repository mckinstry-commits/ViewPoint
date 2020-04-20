CREATE TABLE [dbo].[bEMMR]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[EMTrans] [dbo].[bTrans] NOT NULL,
[BatchId] [dbo].[bBatchID] NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[PostingDate] [dbo].[bDate] NOT NULL,
[ReadingDate] [dbo].[bDate] NOT NULL,
[Source] [dbo].[bSource] NOT NULL,
[PreviousHourMeter] [dbo].[bHrs] NOT NULL,
[CurrentHourMeter] [dbo].[bHrs] NOT NULL,
[PreviousTotalHourMeter] [dbo].[bHrs] NOT NULL,
[CurrentTotalHourMeter] [dbo].[bHrs] NOT NULL,
[Hours] [dbo].[bHrs] NOT NULL,
[PreviousOdometer] [dbo].[bHrs] NOT NULL,
[CurrentOdometer] [dbo].[bHrs] NOT NULL,
[PreviousTotalOdometer] [dbo].[bHrs] NOT NULL,
[CurrentTotalOdometer] [dbo].[bHrs] NOT NULL,
[Miles] [dbo].[bHrs] NOT NULL,
[InUseBatchID] [dbo].[bBatchID] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[udSource] [varchar] (305) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biEMMR] ON [dbo].[bEMMR] ([EMCo], [Mth], [EMTrans]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [biEMMREquip] ON [dbo].[bEMMR] ([EMCo], [Equipment]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [biEMMRAttchID] ON [dbo].[bEMMR] ([UniqueAttchID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btEMMRd    Script Date: 8/28/99 9:37:18 AM ******/
    CREATE   trigger [dbo].[btEMMRd] on [dbo].[bEMMR] for DELETE as
/*-----------------------------------------------------------------
*	CREATED BY: JM 5/23/99
*	MODIFIED By :  TV 02/11/04 - 23061 added isnulls
*					GP 05/26/09 - 133434 added new HQAT insert
*					TRL 02/09/10 Issue 132064 Allow Retro Mete Readings
*
*	This trigger rejects delete in bEMMR (EM Meter Readings) if  the following error condition exists:
*
*		None - Created to show that no conditions are necessary.
*
*/---------------------------------------------------------------- 
declare @errmsg varchar(255), @validcnt int,
/*132064*/
@source bSource,@co bCompany,@equip bEquip,  @actualdate bDate,@currhourmeter bHrs, @currodometer bHrs,
@errtext varchar(255),@rcode int

if @@rowcount = 0 return

set nocount on

/*132064 START*/
select @rcode = 0
-- Get Source for deleted record. 
select @source = [Source] from deleted

if @source = 'EMMeter' 
begin
	--Get current Meter Readings
	select @co =EMCo,@equip=Equipment,  @actualdate =ReadingDate,@currhourmeter=CurrentHourMeter, @currodometer =CurrentOdometer
	from deleted 
	
	/*1.  Update on Meter Readings, If Retro or If correction, update the following meter reading in EMMR */
	/*2.  Update on the next Meter Readings in EMMR if next meter reading not in current batch as new or changed record*/
	exec @rcode = dbo.vspEMMRUpdateNextReading @co, 'Y'/*DeleteTriggerYN*/,@equip, @actualdate, 
	@currhourmeter,@currodometer, @errtext output  
    	if @rcode <> 0
    	begin
     	select @errmsg = @errtext, @rcode = 1
     	goto error
	end 
end 
/*132064   END*/ 
	
-- Delete attachments if they exist. Make sure UniqueAttchID is not null
insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
select AttachmentID, suser_name(), 'Y' 
from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID                  
where d.UniqueAttchID is not null    

return

error:

select @errmsg = isnull(@errmsg,'') + ' - cannot delete EM Meter Reading!'
RAISERROR(@errmsg, 11, -1);
rollback transaction



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  trigger [dbo].[btEMMRi] on [dbo].[bEMMR] for INSERT as

/*-----------------------------------------------------------------
*	CREATED BY: JM 5/23/99
*	MODIFIED By :  bc 9/13/99
*		JM 2/20/00 - Added: If current odo or hrs being inserted = 0, update current to previous
*		and currenttotal to previoustotal. Ref Issue 6304.
*		TV 11/11/03 17046 Clean up + Updating EMEM
*		TV 1/19/04 23538 Added UpdateYN flag to stop HQ auditing
*		GF 02/17/2004 - issue #23799 - problem when updating EMEM.HourReading from source 'MS'. Doubling.
*		TV 02/11/04 - 23061 added isnulls
*		TV 08/30/01 25432 - UpdateYN flag set to N during posting, not set back to Y after
*		TV 09/16/04 25496 - Change to odometer default in 5.9 can result in incorrect meter reading posted
*		TV 06/06/05 27408 - Only allow 0 entries when a Meeter reading
*		TRL 01/20/10 132064, changed how previous amounts update
*		JB & TL 8/20/10	140964	-	Fixed problems with the zeroing out of fields and how previous values are calculated.
*		TRL 12/29/10 142643 - Fixed Update last EMMR trans on EMEM Update
*		JVH 6/10/11 TK-06049 - Added special handling for the SM source
*
*	This trigger rejects insertion in bEMMR (EM Meter Readings) if the following error condition exists:
*
*		Invalid EMCo vs bEMCO
*		Invalid Equipment vs bEMEM
*
*/----------------------------------------------------------------
declare @ememhourdate bDate, @ememhourreading bHrs, @ememododate bDate, @ememodoreading bHrs, @emmremco bCompany,
@emmrequipment bEquip, @emmrcurrenthourmeter bHrs, @emmrcurrentodometer bHrs, @emmrreadingdate bDate,
@errmsg varchar(255), @numrows int, @validcnt int, @emmrmth bMonth, @emmremtrans bTrans,@job bJob,
/*132064*/
@emmrprevioustotalhourmeter bHrs,
@emmrprevioustotalodometer bHrs,
@emmrprevioushourmeter bHrs, 
@emmrpreviousodometer bHrs,
@rcode int, @errtext varchar(255)

   
--from EMMR
declare @source bSource, @premusage char(1), @costparts char(1), @fuelmeter char(1), @joblocupdate char(1)

select @numrows = @@rowcount, @rcode = 0

if @numrows = 0 return

set nocount on
   
--Validate EMCo. 
select @validcnt = count(*) from bEMCO e with(nolock) inner join  inserted i on e.EMCo = i.EMCo
if @validcnt <> @numrows
begin
	select @errmsg = 'Invalid EMCo'
	goto error
end

--Validate Equipment. 
select @validcnt = count(*) from bEMEM e with(nolock) inner join inserted i on e.EMCo = i.EMCo and e.Equipment = i.Equipment
if @validcnt <> @numrows
begin
	select @errmsg = 'Invalid Equipment'
	goto error
end

select  @premusage = UsageMeterUpdate, @costparts = CostPartsMeterUpdate, 
@fuelmeter = FuelMeterUpdate, @joblocupdate = JobLocationUpdate
from dbo.EMCO e with(nolock)
inner join Inserted i on e.EMCo = i.EMCo  
   
SELECT  
	@ememhourdate = ISNULL(e.HourDate, ''), 
	@ememododate = ISNULL(e.OdoDate, ''),
	@ememhourreading = e.HourReading,
	@ememodoreading = e.OdoReading, 
	@emmremco = i.EMCo, 
	@emmrequipment = i.Equipment,
	@emmrreadingdate = i.ReadingDate, 
	@emmrcurrenthourmeter = i.CurrentHourMeter, 
	@emmrcurrentodometer = i.CurrentOdometer, 
	@source = i.[Source],
	@emmrmth = i.Mth, 
	@emmremtrans = i.EMTrans,
	/*132064*/
	@emmrprevioustotalhourmeter = i.CurrentTotalHourMeter - i.[Hours],	
	@emmrprevioustotalodometer = i.CurrentTotalOdometer - i.Miles,    
	@emmrprevioushourmeter = CASE WHEN i.[Source] NOT IN ('PR','MS','EMRev') THEN e.HourReading ELSE i.CurrentHourMeter - i.[Hours] END , 
	@emmrpreviousodometer = CASE WHEN i.[Source] NOT IN ('PR','MS','EMRev') THEN  e.OdoReading  ELSE i.CurrentOdometer - i.Miles END 
	/*132064*/
	FROM dbo.bEMEM e
	INNER JOIN inserted i ON e.EMCo = i.EMCo AND e.Equipment = i.Equipment	
 	
-- 1/19/04 TV 23538 Added UpdateYN flag to stop HQ auditing
if @source in ('PR','MS','EMRev')
begin--source EM PR Usage    
	if (@premusage) = 'U' 
	begin--when reading date is greater
		if (@emmrreadingdate > @ememhourdate and @emmrcurrenthourmeter <> 0) or
		(@emmrreadingdate = @ememhourdate and @emmrcurrenthourmeter > @ememhourreading)
		begin 
			update bEMEM
			set HourDate = @emmrreadingdate, HourReading = @emmrcurrenthourmeter,UpdateYN = 'N'                
			where EMCo = @emmremco and Equipment = @emmrequipment
		end
		if (@emmrreadingdate = @ememododate and @emmrcurrentodometer > @ememodoreading)or
		(@emmrreadingdate > @ememododate and @emmrcurrentodometer <>0)
		begin 
			update bEMEM
			set OdoDate = @emmrreadingdate, OdoReading = @emmrcurrentodometer, UpdateYN = 'N'                
			where EMCo = @emmremco and Equipment = @emmrequipment
		end
	end--when reading date is greater

	if (@premusage) = 'A' 
	begin--always update meter, never date
		update bEMEM
		set HourReading = @emmrcurrenthourmeter,
		OdoReading = @emmrcurrentodometer, UpdateYN = 'N'
		Where EMCo = @emmremco and Equipment = @emmrequipment
	end--always update meter, never date

	if (@premusage) = 'N' 
	begin  --always update Meter, update date when greater than current
		update bEMEM
		set HourDate = case when @emmrreadingdate > @ememhourdate	then @emmrreadingdate else @ememhourdate end, 
		OdoDate = case when @emmrreadingdate > @ememododate	then @emmrreadingdate else @ememododate end, 
		HourReading =  @emmrcurrenthourmeter,
		OdoReading = @emmrcurrentodometer, UpdateYN = 'N'
		where EMCo = @emmremco and Equipment = @emmrequipment
		--end --always update Meter, update date when greater than current
	end 

	goto UpdateEnd
end--source EM PR Usage   
 
if @source in ('EMAdj','EMParts')
begin--source Cost Adj. PartsPosting 
	if (@costparts) = 'U' 
	begin--when reading date is greater
		if (@emmrreadingdate > @ememhourdate and @emmrcurrenthourmeter <> 0) or
		(@emmrreadingdate = @ememhourdate and @emmrcurrenthourmeter > @ememhourreading)
		begin 
			update bEMEM
			set HourDate = @emmrreadingdate, HourReading = @emmrcurrenthourmeter,UpdateYN = 'N'                
			where EMCo = @emmremco and Equipment = @emmrequipment
		end
		if (@emmrreadingdate = @ememododate and @emmrcurrentodometer > @ememodoreading)or
		(@emmrreadingdate > @ememododate and @emmrcurrentodometer <>0)
		begin 
			update bEMEM
			set OdoDate = @emmrreadingdate, OdoReading = @emmrcurrentodometer, UpdateYN = 'N'                
			where EMCo = @emmremco and Equipment = @emmrequipment
		end
	end--when reading date is greater

	if (@costparts) = 'A' 
	begin--always update meter, never date
		update bEMEM
		set HourReading = @emmrcurrenthourmeter,
		OdoReading = @emmrcurrentodometer, UpdateYN = 'N'
		Where EMCo = @emmremco and Equipment = @emmrequipment
	end--always update meter, never date

	if (@costparts) = 'N' 
	begin  --always update Meter, update date when greater than current
		update bEMEM
		set HourDate = case when @emmrreadingdate > @ememhourdate	then @emmrreadingdate else @ememhourdate end, 
		OdoDate = case when @emmrreadingdate > @ememododate	then @emmrreadingdate else @ememododate end, 
		HourReading = @emmrcurrenthourmeter,
		OdoReading = @emmrcurrentodometer, UpdateYN = 'N'
		where EMCo = @emmremco and Equipment = @emmrequipment
	end --always update Meter, update date when greater than current
	
	goto UpdateEnd
end--source Cost Adj. PartsPosting 

if @source in ('EMFuel')
begin--source Fuel
	if (@fuelmeter) = 'U' 
	begin--when reading date is greater
		if (@emmrreadingdate > @ememhourdate and @emmrcurrenthourmeter <> 0) or
		(@emmrreadingdate = @ememhourdate and @emmrcurrenthourmeter > @ememhourreading)
		begin 
			update bEMEM
			set HourDate = @emmrreadingdate, HourReading = @emmrcurrenthourmeter,UpdateYN = 'N'                
			where EMCo = @emmremco and Equipment = @emmrequipment
		end
		if (@emmrreadingdate = @ememododate and @emmrcurrentodometer > @ememodoreading)or
		(@emmrreadingdate > @ememododate and @emmrcurrentodometer <>0)
		begin 
			update bEMEM
			set OdoDate = @emmrreadingdate, OdoReading = @emmrcurrentodometer, UpdateYN = 'N'                
			where EMCo = @emmremco and Equipment = @emmrequipment
		end
	end--when reading date is greater

	if (@fuelmeter) = 'A' 
	begin--always update meter, never date
		update bEMEM
		set HourReading = @emmrcurrenthourmeter,	OdoReading = @emmrcurrentodometer, UpdateYN = 'N'
		Where EMCo = @emmremco and Equipment = @emmrequipment
	end--always update meter, never date

	if (@fuelmeter) = 'N' 
	begin  --always update Meter, update date when greater than current
		update bEMEM
		set HourDate = case when @emmrreadingdate > @ememhourdate 	then @emmrreadingdate else @ememhourdate end, 
		OdoDate = case when @emmrreadingdate > @ememododate then @emmrreadingdate else @ememododate end, 
		HourReading = @emmrcurrenthourmeter ,
		OdoReading =  @emmrcurrentodometer, 
		UpdateYN = 'N'
		where EMCo = @emmremco and Equipment = @emmrequipment
	end --always update Meter, update date when greater than current

	goto UpdateEnd
end--source Fuel

if @source = 'SM'
begin
	--We are going to allow all updates from SM that are the same or greater reading date since 
	--they are always hour adjustments and
	--never a current reading. The current reading is automatically figured out in the EMRD trigger.
	if @emmrreadingdate >= @ememhourdate
	begin
		update dbo.bEMEM
		set HourDate = @emmrreadingdate, HourReading = @emmrcurrenthourmeter, UpdateYN = 'N'
		where EMCo = @emmremco and Equipment = @emmrequipment
	end
end

if @source not in ('PR','MS','EMRev','EMFuel','EMAdj','EMParts','EMEM Init','EMEMUpdate','SM')
begin
	--All others
	if (@emmrreadingdate > @ememhourdate and @emmrcurrenthourmeter <> 0) or
	(@emmrreadingdate = @ememhourdate and @emmrcurrenthourmeter > @ememhourreading)
	begin
		update bEMEM
		set HourDate = @emmrreadingdate, HourReading = @emmrcurrenthourmeter,UpdateYN = 'N'                
		where EMCo = @emmremco and Equipment = @emmrequipment
	end
	if (@emmrreadingdate = @ememododate and @emmrcurrentodometer > @ememodoreading)or
	(@emmrreadingdate > @ememododate and @emmrcurrentodometer <>0)
	begin 
		update bEMEM
		set OdoDate = @emmrreadingdate, OdoReading = @emmrcurrentodometer, UpdateYN = 'N'                
		where EMCo = @emmremco and Equipment = @emmrequipment
	end
end--All others

UpdateEnd:
	-- TV 08/30/01 25432 - UpdateYN flag set to N during posting, not set back to Y after
	update bEMEM
	set UpdateYN = 'Y'                
	where EMCo = @emmremco and Equipment = @emmrequipment
 
	--Ref Issue 6304.  
	--TV 06/06/05 27408 - Only allow 0 entries when a Meeter reading
	if @source <> 'EMMeter' and @source <> 'EMEMUpdate' /*Issue 142643*/
		and @source <> 'SM' --SM needs to be allowed to have 0 hour updates
	Begin
		if (select isnull(CurrentOdometer,0) from inserted i) = 0
		begin
			update bEMMR
			set CurrentOdometer = @emmrpreviousodometer, CurrentTotalOdometer = @emmrprevioustotalodometer, Miles = 0
			where EMCo = @emmremco and Mth = @emmrmth and EMTrans = @emmremtrans
		end
		if (select isnull(CurrentHourMeter,0) from inserted i) = 0
		begin
			update bEMMR
			set CurrentHourMeter = @emmrprevioushourmeter, CurrentTotalHourMeter = @emmrprevioustotalhourmeter
			where EMCo = @emmremco and Mth = @emmrmth and EMTrans = @emmremtrans
		end
	end

	/*132064 START*/
	if @source in ('EMMeter')
	begin	--All others
		/*1.  Update on Meter Readings, If Retro or If correction, update the following meter reading in EMMR */
		/*2.  Update on the next Meter Readings in EMMR if next meter reading not in current batch as new or changed record*/
		exec @rcode = dbo.vspEMMRUpdateNextReading @emmremco, 'N'/*DeleteTriggerYN*/,@emmrequipment, @emmrreadingdate, 
		@emmrcurrenthourmeter,@emmrcurrentodometer, @errtext output 
    		if @rcode <> 0
    		begin
     		select @errmsg = @errtext, @rcode = 1
     		goto error
		end 
	end   
	/*132064 END*/
return

error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot insert EM Meter Readings!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/***********************************************/
CREATE trigger [dbo].[btEMMRu] on [dbo].[bEMMR] for UPDATE as
/***************************************************************
*	CREATED BY: JM 5/19/99
*	MODIFIED By :  bc 9/13/99
*		JM 3/26/02 - Ref Issue 16582 - Changed to not update bEMEM if this trigger is being fired by the 
*			insert of an existing detail  record into bEMBF (ie by btEMBFi updating InUseBatchId in bEMMR).
*		TV 03/13/03 Clean up
*		TV 11/11/03 17046 Clean up + Updating EMEM
*		TV 1/19/04 23538 Added UpdateYN flag to stop HQ auditing
* 		TV 02/11/04 - 23061 added isnulls
*		TV 08/30/01 25432 - UpdateYN flag set to N during posting, not set back to Y after
*		TV 09/16/04 25496 - Change to odometer default in 5.9 can result in incorrect meter reading posted
*		TJL 11/19/07 - Issue #124357:  EMEM OdoReading, HourReading, & Dates not being updated on EM Meter Reading Posting
*									   Corrects Issue #16582 done 03/2002
*		GF 11/07/2008 - issue #130920 - need to use a cursor if @numrows > 0
*		JonathanP 01/09/08 - #128879 - Added code to skip procedure if only UniqueAttachID changed.
*		GP 6/15/2010 - Issue #140075 - Added i.ReadingDate to cursor select statement to match fetch.
*
*
*	This trigger rejects update in bEMMR (EM Meter Readings) if  the following error condition exists:
*
*		Change in key fields (EMCo, Equipment or EMTrans)
* 
****************************************************************/
declare @ememhourdate bDate, @ememhourreading bHrs, @ememododate bDate, @ememodoreading bHrs, @emmremco bCompany,
@emmrequipment bEquip, @emmrcurrenthourmeter bHrs, @emmrcurrentodometer bHrs, @emmrreadingdate bDate,
@emmroldcurrenthourmeter bHrs, @emmroldcurrentodometer bHrs, @emmroldreadingdate bDate,
@errmsg varchar(255), @numrows int, @validcnt int,
/*132064*/
@rcode int, @errtext varchar(255)

--from EMCO
declare @source bSource, @premusage char(1), @costparts char(1), @fuelmeter char(1), @joblocupdate char(1)

select @numrows = @@rowcount, @rcode =0

if @numrows = 0 return

set nocount on
      
--If the only column that changed was UniqueAttachID, then skip validation.        
IF dbo.vfOnlyColumnUpdated(COLUMNS_UPDATED(), 'bEMMR', 'UniqueAttchID') = 1
BEGIN 
	goto Trigger_Skip
END    
      
-- Check for changes to key fields. 
if update(EMCo)
begin
	select @errmsg = 'Cannot change EMCo'
	goto error
end
if update(Mth)
begin
	select @errmsg = 'Cannot change Mth'
	goto error
end
if update(EMTrans)
begin
	select @errmsg = 'Cannot change EMTrans'
	goto error
end
   
------------------
-- CURSOR BEGIN --
------------------
if @numrows = 1
	begin
		select @emmremco = i.EMCo, @emmrequipment = i.Equipment, @emmrreadingdate = i.ReadingDate,
		@emmrcurrenthourmeter = i.CurrentHourMeter, @emmrcurrentodometer = i.CurrentOdometer,
		@source = i.Source, @emmroldcurrenthourmeter = d.CurrentHourMeter,
		@emmroldcurrentodometer = d.CurrentOdometer, @emmroldreadingdate = d.ReadingDate,
		@ememhourdate = isnull(e.HourDate,''), @ememododate = isnull(e.OdoDate,''),
		@ememhourreading = e.HourReading, @ememodoreading = e.OdoReading,
		@premusage = c.UsageMeterUpdate, @costparts = c.CostPartsMeterUpdate, 
		@fuelmeter = c.FuelMeterUpdate, @joblocupdate = c.JobLocationUpdate
		from inserted i join deleted d on d.EMCo = i.EMCo and d.Mth = i.Mth and d.EMTrans = i.EMTrans
		join bEMEM e on e.EMCo = i.EMCo and e.Equipment = i.Equipment
		join bEMCO c on c.EMCo = i.EMCo
	end
else
	begin
		declare bEMMR_update cursor LOCAL FAST_FORWARD
		for select i.EMCo, i.Equipment, i.ReadingDate, i.CurrentHourMeter, i.CurrentOdometer, i.Source,
			d.CurrentHourMeter, d.CurrentOdometer, d.ReadingDate,
			isnull(e.HourDate,''), isnull(e.OdoDate,''), e.HourReading, e.OdoReading,
			c.UsageMeterUpdate, c.CostPartsMeterUpdate, c.FuelMeterUpdate, c.JobLocationUpdate
			from inserted i join deleted d on d.EMCo = i.EMCo and d.Mth = i.Mth and d.EMTrans = i.EMTrans
			join bEMEM e on e.EMCo = i.EMCo and e.Equipment = i.Equipment
			join bEMCO c on c.EMCo = i.EMCo

		open bEMMR_update

		fetch next from bEMMR_update into @emmremco, @emmrequipment, @emmrreadingdate, @emmrcurrenthourmeter,
		@emmrcurrentodometer, @source, @emmroldcurrenthourmeter, @emmroldcurrentodometer,
		@emmroldreadingdate, @ememhourdate, @ememododate, @ememhourreading, @ememodoreading,
		@premusage, @costparts, @fuelmeter, @joblocupdate

		if @@fetch_status <> 0
		begin
			select @errmsg = 'Cursor error'
			goto error
		end
	end

update_check:

-- 1/19/04 TV 23538 Added UpdateYN flag to stop HQ auditing
if @source in ('PR','MS','EMRev')
begin--source EM PR Usage    
  	if (@premusage) = 'U' 
	begin--when reading date is greater
		if (@emmrreadingdate > @ememhourdate and @emmrcurrenthourmeter <> 0) or
		(@emmrreadingdate = @ememhourdate and @emmrcurrenthourmeter > @ememhourreading)
		begin 
			update bEMEM
			set HourDate = @emmrreadingdate, HourReading = @emmrcurrenthourmeter, UpdateYN = 'N'                
			where EMCo = @emmremco and Equipment = @emmrequipment
		end
		if (@emmrreadingdate = @ememododate and @emmrcurrentodometer > @ememodoreading)or
		(@emmrreadingdate > @ememododate and @emmrcurrentodometer <>0)
		begin 
			update bEMEM
			set OdoDate = @emmrreadingdate, OdoReading = @emmrcurrentodometer, UpdateYN = 'N'                
			where EMCo = @emmremco and Equipment = @emmrequipment
		end
	end--when reading date is greater

	if (@premusage) = 'A' 
	begin--always update meter, never date
		update bEMEM
		set HourReading = @emmrcurrenthourmeter,
		OdoReading = @emmrcurrentodometer, UpdateYN = 'N'
		Where EMCo = @emmremco and Equipment = @emmrequipment
	end--always update meter, never date

	if (@premusage) = 'N' 
	begin  --always update Meter, update date when greater than current
		update bEMEM
		set HourDate = case when @emmrreadingdate > @ememhourdate 
					 then @emmrreadingdate else @ememhourdate end, 
			OdoDate = case when @emmrreadingdate > @ememododate 
					 then @emmrreadingdate else @ememododate end, 
			HourReading = @emmrcurrenthourmeter,
			OdoReading = @emmrcurrentodometer, UpdateYN = 'N'
		where EMCo = @emmremco and Equipment = @emmrequipment
        --end --always update Meter, update date when greater than current
	end 

	goto UpdateEnd
end--source EM PR Usage 

if @source in ('EMAdj','EMParts')
begin--source Cost Adj. PartsPosting 
  	if (@costparts) = 'U' 
	begin--when reading date is greater
		if (@emmrreadingdate > @ememhourdate and @emmrcurrenthourmeter <> 0) or
		(@emmrreadingdate = @ememhourdate and @emmrcurrenthourmeter > @ememhourreading)
		begin 
			update bEMEM
			set HourDate = @emmrreadingdate, HourReading = @emmrcurrenthourmeter, UpdateYN = 'N'                
			where EMCo = @emmremco and Equipment = @emmrequipment
		end
		
		if (@emmrreadingdate = @ememododate and @emmrcurrentodometer > @ememodoreading)or
		(@emmrreadingdate > @ememododate and @emmrcurrentodometer <>0)
		begin 
			update bEMEM
			set OdoDate = @emmrreadingdate, OdoReading = @emmrcurrentodometer, UpdateYN = 'N'                
			where EMCo = @emmremco and Equipment = @emmrequipment
		end
	end--when reading date is greater

	if (@costparts) = 'A' 
	begin--always update meter, never date
		update bEMEM
  		set HourReading = @emmrcurrenthourmeter,
			OdoReading = @emmrcurrentodometer, UpdateYN = 'N'
  		Where EMCo = @emmremco and Equipment = @emmrequipment
	end--always update meter, never date

	if (@costparts) = 'N' 
	begin  --always update Meter, update date when greater than current
		update bEMEM
		set HourDate = case when @emmrreadingdate > @ememhourdate 
					then @emmrreadingdate else @ememhourdate end, 
			OdoDate = case when @emmrreadingdate > @ememododate 
					then @emmrreadingdate else @ememododate end, 
			HourReading = @emmrcurrenthourmeter,
			OdoReading = @emmrcurrentodometer, UpdateYN = 'N'
		where EMCo = @emmremco and Equipment = @emmrequipment
       end --always update Meter, update date when greater than current

	goto UpdateEnd
end--source Cost Adj. PartsPosting 

if @source in ('EMFuel')
begin--source Fuel
	if (@fuelmeter) = 'U' 
	begin--when reading date is greater
		if (@emmrreadingdate > @ememhourdate and @emmrcurrenthourmeter <> 0) or
		(@emmrreadingdate = @ememhourdate and @emmrcurrenthourmeter > @ememhourreading)
		begin 
			update bEMEM
			set HourDate = @emmrreadingdate, HourReading = @emmrcurrenthourmeter, UpdateYN = 'N'                
			where EMCo = @emmremco and Equipment = @emmrequipment
		end
		if (@emmrreadingdate = @ememododate and @emmrcurrentodometer > @ememodoreading)or
		(@emmrreadingdate > @ememododate and @emmrcurrentodometer <>0)
		begin 
			update bEMEM
			set OdoDate = @emmrreadingdate, OdoReading = @emmrcurrentodometer, UpdateYN = 'N'                
			where EMCo = @emmremco and Equipment = @emmrequipment
		end
	end--when reading date is greater

	if (@fuelmeter) = 'A' 
	begin--always update meter, never date
		update bEMEM
		set HourReading = @emmrcurrenthourmeter,
			OdoReading =  @emmrcurrentodometer, UpdateYN = 'N'
		Where EMCo = @emmremco and Equipment = @emmrequipment
	end--always update meter, never date

	if (@fuelmeter) = 'N' 
	begin  --always update Meter, update date when greater than current
		update bEMEM
		set HourDate = case when @emmrreadingdate > @ememhourdate 
			then @emmrreadingdate else @ememhourdate end, 
			OdoDate = case when @emmrreadingdate > @ememododate
				then @emmrreadingdate else @ememododate end, 
			HourReading = @emmrcurrenthourmeter,
			OdoReading = @emmrcurrentodometer, UpdateYN = 'N'
		where EMCo = @emmremco and Equipment = @emmrequipment
	end --always update Meter, update date when greater than current

	goto UpdateEnd
end--source Fuel

if @source in ('EMMeter')
begin--source Meter
	if (@emmrreadingdate <> @emmroldreadingdate) or (@emmrcurrenthourmeter <> @emmroldcurrenthourmeter)
	or (@emmrcurrentodometer <> @emmroldcurrentodometer)
	/* When an EM Meter Readings transaction first gets added back into a batch, the EMMR.InUseBatchID value will get updated
	   from the EMBF insert trigger and the EMMR update trigger (this trigger) fires.  During this time, we do NOT 
	   want to update EMEM!  Only during posting if an appropriate value has changed that will affect EMEM values
	   do we then proceed to update EMEM. 

	   This corrects Issue #16582 coded in 03/2002 which then created this current problem for
	   Issue #124357. */
	begin
		if (@emmrreadingdate > @ememhourdate and @emmrcurrenthourmeter <> 0) or
		(@emmrreadingdate = @ememhourdate and @emmrcurrenthourmeter > @ememhourreading)
		begin 
			update bEMEM
			set HourDate = @emmrreadingdate, HourReading = @emmrcurrenthourmeter, UpdateYN = 'N'                
			where EMCo = @emmremco and Equipment = @emmrequipment
		end
		if (@emmrreadingdate = @ememododate and @emmrcurrentodometer > @ememodoreading)or
		(@emmrreadingdate > @ememododate and @emmrcurrentodometer <>0)
		begin 
			update bEMEM
			set OdoDate = @emmrreadingdate, OdoReading = @emmrcurrentodometer, UpdateYN = 'N'                
			where EMCo = @emmremco and Equipment = @emmrequipment
		end
	end

	/*132064 START*/
		begin	
		/*1.  Update on Meter Readings, If Retro or If correction, update the following meter reading in EMMR */
		/*2.  Update on the next Meter Readings in EMMR if next meter reading not in current batch as new or changed record*/
		exec @rcode = dbo.vspEMMRUpdateNextReading @emmremco, 'N'/*DeleteTriggerYN*/,@emmrequipment, @emmrreadingdate, 
		@emmrcurrenthourmeter,@emmrcurrentodometer, @errmsg output
    		if @rcode <> 0
    		begin
     		select @errmsg = @errtext, @rcode = 1
     		goto error
		end 
	end   
	/*132064 END*/
	
	goto UpdateEnd
end--source Meter

--All other sources not listed above.  (Catch All)
if (@emmrreadingdate > @ememhourdate and @emmrcurrenthourmeter <> 0) or
(@emmrreadingdate = @ememhourdate and @emmrcurrenthourmeter > @ememhourreading)
begin 
	update bEMEM
	set HourDate = @emmrreadingdate, HourReading = @emmrcurrenthourmeter,UpdateYN = 'N'                
	where EMCo = @emmremco and Equipment = @emmrequipment
end

if (@emmrreadingdate = @ememododate and @emmrcurrentodometer > @ememodoreading)or
(@emmrreadingdate > @ememododate and @emmrcurrentodometer <>0)
begin 
	update bEMEM
	set OdoDate = @emmrreadingdate, OdoReading = @emmrcurrentodometer, UpdateYN = 'N'                
	where EMCo = @emmremco and Equipment = @emmrequipment
end

UpdateEnd:
---- TV 08/30/01 25432 - UpdateYN flag set to N during posting, not set back to Y after
update bEMEM
set UpdateYN = 'Y'
where EMCo = @emmremco and Equipment = @emmrequipment

if @numrows > 1
begin
	fetch next from bEMMR_update into @emmremco, @emmrequipment, @emmrreadingdate, @emmrcurrenthourmeter,
	@emmrcurrentodometer, @source, @emmroldcurrenthourmeter, @emmroldcurrentodometer,
	@emmroldreadingdate, @ememhourdate, @ememododate, @ememhourreading, @ememodoreading,
	@premusage, @costparts, @fuelmeter, @joblocupdate
	if @@fetch_status = 0
		begin
			goto update_check
		end
	else
		begin
			close bEMMR_update
			deallocate bEMMR_update
		end
	end

Trigger_Skip:
      
return

error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update EM Meter Reading!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

GO

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMMR] ([KeyID]) ON [PRIMARY]
GO
