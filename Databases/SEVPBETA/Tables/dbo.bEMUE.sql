CREATE TABLE [dbo].[bEMUE]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[AUTemplate] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[RulesTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[PhaseGrp] [dbo].[bGroup] NOT NULL,
[JCPhase] [dbo].[bPhase] NOT NULL,
[MaxPerPD] [dbo].[bDollar] NULL,
[MaxPerMonth] [dbo].[bDollar] NULL,
[MaxPerJob] [dbo].[bDollar] NULL,
[MinPerPd] [dbo].[bDollar] NULL,
[DayStartTime] [smalldatetime] NULL,
[DayStopTime] [smalldatetime] NULL,
[HrsPerDay] [dbo].[bHrs] NULL,
[Br1StartTime] [smalldatetime] NULL,
[Br1StopTime] [smalldatetime] NULL,
[Br2StartTime] [smalldatetime] NULL,
[Br2StopTime] [smalldatetime] NULL,
[Br3StartTime] [smalldatetime] NULL,
[Br3StopTime] [smalldatetime] NULL,
[BillingStartsOnTrnsfrInDateYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bEMUE_BillingStartsOnTrnsfrInDateYN] DEFAULT ('N'),
[UseEstDateOutYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bEMUE_UseEstDateOutYN] DEFAULT ('N')
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMUEd    Script Date: 8/28/99 9:37:24 AM ******/
   CREATE   trigger [dbo].[btEMUEd] on [dbo].[bEMUE] for DELETE as
   

declare @errmsg varchar(255), @validcnt int
   
   /*-----------------------------------------------------------------
    *	CREATED BY: bc  08/11/99
    *	MODIFIED By :  TV 02/11/04 - 23061 added isnulls
    *
    *
    */----------------------------------------------------------------
   
   if @@rowcount = 0 return
   set nocount on
   
   
   /* Audit inserts */
   insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bEMUE','EM Company: ' + convert(char(3), d.EMCo)
   		 + ' Auto Template: ' + d.AUTemplate + ' Equipment: ' + d.Equipment, d.EMCo, 'D',
   		null, null, null, getdate(), SUSER_SNAME()
   	from deleted d, EMCO e
           where d.EMCo = e.EMCo and e.AuditEquipment = 'Y'
   
   return
   
   error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot delete EMUE!'
       RAISERROR(@errmsg, 11, -1);
   
       rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btEMUEi    Script Date: 8/28/99 9:37:24 AM ******/
CREATE trigger [dbo].[btEMUEi] on [dbo].[bEMUE] for insert as
/*--------------------------------------------------------------
 * Created:  bc  08/11/99
 * Modified: TV 02/11/04 - 23061 added isnulls
 *				TV 03/17/04 23742 Was not validating Phase Part.
 *			GG 10/16/07 - #125791 - fix for DDDTShared
 *			GF 07/19/2012 TK-16508 fix break start/stop messages and general cleanup
 *
 * Insert trigger for EMUE
 *
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255),
		@validcnt int, @nullcnt INT, @rcode int

declare @emco bCompany, @template varchar(10), @equip bEquip, @maxperpd bDollar, @minperpd bDollar,
		@daystart smalldatetime, @daystop smalldatetime, @br1start smalldatetime, @br1stop smalldatetime,
		@br2start smalldatetime, @br2stop smalldatetime, @br3start smalldatetime, @br3stop smalldatetime

declare @jcco bCompany, @validphasechars tinyint, @inputmask varchar(30), @pphase bPhase, @phasegroup bGroup

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on
   
/* Validate EMCo */
select @validcnt = count(*) from bEMCO r JOIN inserted i ON i.EMCo = r.EMCo
if @validcnt <> @numrows
	begin
	select @errmsg = 'EM Company is Invalid '
	goto error
	end
   
/* Validate Auto Template */
select @validcnt = count(*) from bEMUH r JOIN inserted i ON i.EMCo = r.EMCo and i.AUTemplate = r.AUTemplate
if @validcnt  <> @numrows
	begin
	select @errmsg = 'Auto Template is Invalid '
	goto error
	end

/* Validate Equipment */
select @validcnt = count(*) from bEMEM r JOIN inserted i ON i.EMCo = r.EMCo and i.Equipment = r.Equipment
if @validcnt <> @numrows
	begin
	select @errmsg = 'Equipment is Invalid '
	goto error
	end

/* Validate Rules Table*/
select @validcnt = count(*) from bEMUR r JOIN inserted i ON i.EMCo = r.EMCo and i.RulesTable = r.RulesTable
select @nullcnt = count(*) from inserted i where i.RulesTable is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'The Rules Table is Invalid '
	goto error
	end

--TV 03/17/04 23742 Was not validating Phase Part.
if update(JCPhase)
	begin
	/* Old code */
	/*  select @validcnt = count(*) from bJCPM r JOIN inserted i ON i.PhaseGrp = r.PhaseGroup and i.JCPhase = r.Phase
	if @validcnt <> @numrows
	begin
	select @errmsg = 'Phase is Invalid '
	goto error
	end*/
	/* New Code per  Issue 18749 Rej 2 */
	select @validcnt = count(*) from bJCPM r JOIN inserted i ON i.PhaseGrp = r.PhaseGroup and  i.JCPhase = r.Phase
	 /* If exact match not found, search by valid section of the Phase */
	if @validcnt <> @numrows
		begin
		/* Get the mask for bPhase */
		select @inputmask=InputMask from dbo.DDDTShared (nolock) where Datatype = 'bPhase'
		/* Loop on EMUC.EMCo */
		select @emco = min(EMCo) from inserted
		while @emco is not null
			begin
			/* Get JCCo from EMCO */
			select @jcco = JCCo from bEMCO where EMCo = @emco
			if @@rowcount=0
				begin
				select @errmsg = 'Job cost company ' + isnull(convert(varchar(3), @jcco),'') + ' not found', @rcode = 1
				goto error
				end
			/* Get PhaseGroup from HQCO */
			select @phasegroup = PhaseGroup from bHQCO where HQCo = @jcco
			/* Get ValidPhaseChars from JCCO */
			select @validphasechars = ValidPhaseChars from bJCCO with (nolock) where JCCo=@jcco
			if @validphasechars=0
				begin
				select @errmsg = 'Missing Phase', @rcode = 1
				goto error
				end
			/* Loop on EMUC.AUTemplate */
			select @template = min(AUTemplate) from inserted where EMCo = @emco
		while @template is not null
			begin
			/* Loop on EMUC.Category */
			select @equip = min(Equipment) from inserted where EMCo = @emco and AUTemplate = @template
			while @equip is not null
				begin
				/* Get Phase chunk to validate with */
				select @pphase=substring(JCPhase,1,@validphasechars) + '%'
				from inserted
				where EMCo = @emco and AUTemplate = @template and Equipment = @equip
				/* Validate the Phase chunk */
				select TOP 1 @errmsg = Description
				from bJCPM where PhaseGroup = @phasegroup and Phase like @pphase
				Group By PhaseGroup, Phase, Description
				if @@rowcount = 0
					begin
					select @errmsg = 'Phase not setup in Phase Master.', @rcode = 1
					goto error
					end
				select @equip = min(Equipment) from inserted where EMCo = @emco and AUTemplate = @template and Equipment > @equip
				end
 			select @template = min(AUTemplate) from inserted where EMCo = @emco and AUTemplate > @template
				end
			select @emco = min(EMCo) from inserted where EMCo > @emco
 		end	
	end
end
   
/* validate time values */
select @emco = min(EMCo) from inserted
while @emco is not null
 begin
 select @template = min(AUTemplate) from inserted where EMCo = @emco
 while @template is not null
   begin
   select @equip = min(Equipment) from inserted where EMCo = @emco and AUTemplate = @template
   while @equip is not null
    begin
	select @maxperpd = MaxPerPD, @minperpd = MinPerPd, @daystart = DayStartTime, @daystop = DayStopTime,
		   @br1start = Br1StartTime, @br1stop = Br1StopTime,
		   @br2start = Br2StartTime, @br2stop = Br2StopTime,
		   @br3start = Br3StartTime, @br3stop = Br3StartTime
	from inserted
	where EMCo = @emco and AUTemplate = @template and Equipment = @equip
   
   	if @maxperpd is not null and @minperpd is not null
   	  begin
           if @maxperpd < @minperpd
             begin
   	      select @errmsg = 'Maximum amount per period must be greater than the minimum amount per period '
   	      goto error
             end
   	  end
   
   	--if @daystart is not null and @daystop is not null
   	--  begin
    --       if @daystart > @daystop
    --         begin
   	--      select @errmsg = 'The day stop time must be greater than the day start time '
   	--      goto error
    --         end
   	--  end
   
   	--if @br1start is not null and @br1stop is not null
   	--  begin
    --       if @br1start > @br1stop
    --         begin
   	--      select @errmsg = 'The 1st break stop time must be greater than the 1st break start time '
   	--      goto error
    --         end
   	--  end
   
    --   if @br2start is not null and @br2stop is not null
   	--  begin
    --       if @br2start > @br2stop
    --         begin
   	--      select @errmsg = 'The 2nd break stop time must be greater than the 2nd break start time '
   	--      goto error
    --         end
   	--  end
   
    --   if @br3start is not null and @br3stop is not null
   	--  begin
    --       if @br3start > @br3stop
    --         begin
   	--      select @errmsg = 'The 3rd break stop time must be greater than the 3rd break start time '
   	--      goto error
    --         end
   	--  end
   
    --   if @br1stop is not null and @br2start is not null
   	--  begin
    --       if @br1stop > @br2start
    --         begin
   	--      select @errmsg = 'The 1st break stop time must be earlier than the 2nd break start time '
   	--      goto error
    --         end
   	--  end
   
    --   if @br2stop is not null and @br3start is not null
   	--  begin
    --       if @br2stop > @br3start
    --         begin
   	--      select @errmsg = 'The 2nd break stop time must be earlier than the 3rd break start time '
   	--      goto error
    --         end
   	--  end
   
     select @equip = min(Equipment) from inserted where EMCo = @emco and AUTemplate = @template and Equipment > @equip
     end
   select @template = min(AUTemplate) from inserted where EMCo = @emco and AUTemplate > @template
   end
 select @emco = min(EMCo) from inserted where EMCo > @emco
 end


return

error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot insert into EMUE'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btEMUEu    Script Date: 8/28/99 9:37:24 AM ******/
CREATE trigger [dbo].[btEMUEu] on [dbo].[bEMUE] for update as
/*--------------------------------------------------------------
* Created:  bc  08/11/99
* Modified:  TV 02/11/04 - 23061 added isnulls
*			GG 10/16/07 - #125791 - fix for DDDTShared
*		    TRL 02/20/08 - Issue 271172 add PRCo to EMWI
*			TRL 09/02/08 -- Issue 126196 add code to allow Equipment to change if
*			the EM Equipment code is being changed
*			GF 07/19/2012 TK-16508 fix break start/stop messages and general cleanup
*
*		This trigger rejects update in bEMWI (EM Work Order Items) if  the following error condition exists:
*
* Update trigger for EMUE
*
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int, @rcode int
   
declare @emco bCompany, @template varchar(10), @equip bEquip, @maxperpd bDollar, @minperpd bDollar,
		@daystart smalldatetime, @daystop smalldatetime, @br1start smalldatetime, @br1stop smalldatetime,
		@br2start smalldatetime, @br2stop smalldatetime, @br3start smalldatetime, @br3stop smalldatetime
   
declare @jcco bCompany, @validphasechars tinyint, @inputmask varchar(30), @pphase bPhase,
		@phasegroup bGroup, @changeinprogress CHAR(1)
    
select @numrows = @@rowcount, @changeinprogress = 'N'

set nocount on
if @numrows = 0 return

/* see if any fields have changed that is not allowed */
if update(EMCo) or Update(AUTemplate) or Update(Equipment)
begin
	/* Issue 126196 Check to see if equipment code is being changed.
	Select Where EMEM.LastUsedEquipmentCode = EMWH.Equipment*/
	select @changeinprogress=IsNull(ChangeInProgress,'N')
	from bEMEM e, inserted i where e.EMCo = i.EMCo and e.LastUsedEquipmentCode = i.Equipment
	and e.ChangeInProgress = 'Y'

	--Issue 126196 Only run code if Equipment Code is not being changed
	If @changeinprogress = 'N' 
	begin
		select @validcnt = count(*) from inserted i
		JOIN deleted d ON d.EMCo = i.EMCo and d.AUTemplate=i.AUTemplate and d.Equipment = i.Equipment
   
		if @validcnt <> @numrows
		begin
			select @errmsg = 'Primary key fields may not be changed'
			GoTo error
		End
	end
End
   
/* Validate Rules Table*/
if update(RulesTable)
begin
	select @validcnt = count(*) from bEMUR r JOIN inserted i ON
    i.EMCo = r.EMCo and i.RulesTable = r.RulesTable
    select @nullcnt = count(*)
    from inserted i
    where i.RulesTable is null
    if @validcnt + @nullcnt <> @numrows
    begin
       select @errmsg = 'The Rules Table is Invalid '
       goto error
    end
end
   
   
--Issue 126196 Only run code if Equipment Code is not being changed
If @changeinprogress = 'N' 
BEGIN

--TV 03/17/04 23742 Was not validating Phase Part.
if update(JCPhase)
BEGIN
	/* Old code */
    /*  select @validcnt = count(*) from bJCPM r JOIN inserted i ON i.PhaseGrp = r.PhaseGroup and i.JCPhase = r.Phase
    if @validcnt <> @numrows
    begin
    select @errmsg = 'Phase is Invalid '
    goto error
    end*/
    /* New Code per  Issue 18749 Rej 2 */
    select @validcnt = count(*) from bJCPM r JOIN inserted i ON i.PhaseGrp = r.PhaseGroup and  i.JCPhase = r.Phase
    /* If exact match not found, search by valid section of the Phase */
    if @validcnt <> @numrows
    begin
		/* Get the mask for bPhase */
    	select @inputmask=InputMask from dbo.DDDTShared (nolock) where Datatype = 'bPhase'
    	/* Loop on EMUC.EMCo */
    	select @emco = min(EMCo) from inserted
    	while @emco is not null
    	begin
    		/* Get JCCo from EMCO */
    		select @jcco = JCCo from bEMCO where EMCo = @emco
    		if @@rowcount=0
    		begin
    			select @errmsg = 'Job cost company ' + isnull(convert(varchar(3), @jcco),'') + ' not found', @rcode = 1
    			goto error
    		end
    		/* Get PhaseGroup from HQCO */
    		select @phasegroup = PhaseGroup from bHQCO where HQCo = @jcco
    		/* Get ValidPhaseChars from JCCO */
    		select @validphasechars = ValidPhaseChars from bJCCO with (nolock) where JCCo=@jcco
    		if @validphasechars=0
    		begin
    			select @errmsg = 'Missing Phase', @rcode = 1
    			goto error
    		end
    		/* Loop on EMUC.AUTemplate */
    		select @template = min(AUTemplate) from inserted where EMCo = @emco
   			while @template is not null
   			begin
   				/* Loop on EMUC.Category */
   				select @equip = min(Equipment) from inserted where EMCo = @emco and AUTemplate = @template
   				while @equip is not null
   				begin
   					/* Get Phase chunk to validate with */
   					select @pphase=substring(JCPhase,1,@validphasechars) + '%' from inserted
   					where EMCo = @emco and AUTemplate = @template and Equipment = @equip
   					/* Validate the Phase chunk */
   					select TOP 1 @errmsg = Description from bJCPM where PhaseGroup = @phasegroup and Phase like @pphase
   					Group By PhaseGroup, Phase, Description
   					if @@rowcount = 0
   					begin
   						select @errmsg = 'Phase not setup in Phase Master.', @rcode = 1
   						goto error
   					end
   					select @equip = min(Equipment) from inserted where EMCo = @emco and AUTemplate = @template and Equipment > @equip
   				end
   	 			select @template = min(AUTemplate) from inserted where EMCo = @emco and AUTemplate > @template
    		end
    		select @emco = min(EMCo) from inserted where EMCo > @emco
   	 	end	
   	end
END
   
/* validate time values */
select @emco = min(EMCo) from inserted
while @emco is not null
begin
	select @template = min(AUTemplate) from inserted where EMCo = @emco
    while @template is not null
    begin
		select @equip = min(Equipment) from inserted where EMCo = @emco and AUTemplate = @template
		while @equip is not null
        begin
   			select @maxperpd = MaxPerPD, @minperpd = MinPerPd, @daystart = DayStartTime, @daystop = DayStopTime,
					@br1start = Br1StartTime, @br1stop = Br1StopTime,
					@br2start = Br2StartTime, @br2stop = Br2StopTime, 
					@br3start = Br3StartTime, @br3stop = Br3StartTime
   		from inserted
   		where EMCo = @emco and AUTemplate = @template and Equipment = @equip
   
   		if @maxperpd is not null and @minperpd is not null
   		begin
			if @maxperpd < @minperpd
            begin
   				select @errmsg = 'Maximum amount per period must be greater than the minimum amount per period '
   				goto error
             end
   		end
   
   --		if @daystart is not null and @daystop is not null
   --		begin
			--if @daystart > @daystop
   --         begin
   --				select @errmsg = 'The day stop time must be greater than the day start time '
   --				goto error
   --         end
   --		end
   
   --		if @br1start is not null and @br1stop is not null
   --		begin
			--if @br1start > @br1stop
   --         begin
   --				select @errmsg = 'The 1st break stop time must be greater than the 1st break start time '
   --				goto error
   --          end
   --		end
   
		--if @br2start is not null and @br2stop is not null
  -- 		begin
		--	if @br2start > @br2stop
		--	begin
  -- 				select @errmsg = 'The 2nd break stop time must be greater than the 2nd break start time '
  -- 				goto error
  --          end
  -- 		end
   
		--if @br3start is not null and @br3stop is not null
  -- 		begin
		--	if @br3start > @br3stop
  --          begin
  -- 				select @errmsg = 'The 3rd break stop time must be greater than the 3rd break start time '
  -- 				goto error
  --          end
  -- 		end
   
		--if @br1stop is not null and @br2start is not null
  -- 		begin
		--	if @br1stop > @br2start
  --          begin
  -- 				select @errmsg = 'The 1st break stop time must be earlier than the 2nd break start time '
  -- 				goto error
  --          end
  -- 		end
   
		--if @br2stop is not null and @br3start is not null
  -- 		begin
		--	if @br2stop > @br3start
  --          begin
  -- 				select @errmsg = 'The 2nd break stop time must be earlier than the 3rd break start time '
  -- 				goto error
  --          end
  -- 		end
        select @equip = min(Equipment) from inserted where EMCo = @emco and AUTemplate = @template and Equipment > @equip

    end
    select @template = min(AUTemplate) from inserted where EMCo = @emco and AUTemplate > @template

 end
 select @emco = min(EMCo) from inserted where EMCo > @emco
END
---Is Equipment being changed?
END
      
return
   
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update EMUE'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction

GO
CREATE UNIQUE CLUSTERED INDEX [biEMUE] ON [dbo].[bEMUE] ([EMCo], [AUTemplate], [Equipment]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
