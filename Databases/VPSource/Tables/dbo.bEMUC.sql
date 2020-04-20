CREATE TABLE [dbo].[bEMUC]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[AUTemplate] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Category] [dbo].[bCat] NOT NULL,
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
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[BillingStartsOnTrnsfrInDateYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bEMUC_BillingStartsOnTrnsfrInDateYN] DEFAULT ('N'),
[UseEstDateOutYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bEMUC_UseEstDateOutYN] DEFAULT ('N')
) ON [PRIMARY]
ALTER TABLE [dbo].[bEMUC] ADD
CONSTRAINT [FK_bEMUC_bEMCO_EMCo] FOREIGN KEY ([EMCo]) REFERENCES [dbo].[bEMCO] ([EMCo])
ALTER TABLE [dbo].[bEMUC] ADD
CONSTRAINT [FK_bEMUC_bEMUH_AUTemplate] FOREIGN KEY ([EMCo], [AUTemplate]) REFERENCES [dbo].[bEMUH] ([EMCo], [AUTemplate]) ON DELETE CASCADE
ALTER TABLE [dbo].[bEMUC] ADD
CONSTRAINT [FK_bEMUC_bEMCM_Category] FOREIGN KEY ([EMCo], [Category]) REFERENCES [dbo].[bEMCM] ([EMCo], [Category])
ALTER TABLE [dbo].[bEMUC] ADD
CONSTRAINT [FK_bEMUC_bEMUR_RulesTable] FOREIGN KEY ([EMCo], [RulesTable]) REFERENCES [dbo].[bEMUR] ([EMCo], [RulesTable])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMUCd    Script Date: 8/28/99 9:37:23 AM ******/
   CREATE   trigger [dbo].[btEMUCd] on [dbo].[bEMUC] for DELETE as
   

declare @errmsg varchar(255), @validcnt int
   
   /*-----------------------------------------------------------------
    *	CREATED BY: bc  08/11/99
    *	MODIFIED By : TV 02/11/04 - 23061 added isnulls
    *
    *
    */----------------------------------------------------------------
   
   if @@rowcount = 0 return
   set nocount on
   
   
   /* Audit inserts */
   insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bEMUC','EM Company: ' + convert(char(3), d.EMCo)
   		 + ' Auto Template: ' + d.AUTemplate + ' Category: ' + d.Category, d.EMCo, 'D',
   		null, null, null, getdate(), SUSER_SNAME()
   	from deleted d, EMCO e
           where d.EMCo = e.EMCo and e.AuditEquipment = 'Y'
   
   return
   
   error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot delete EMUC!'
       RAISERROR(@errmsg, 11, -1);
   
       rollback transaction
   
   
   
   
   
  
 



GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE trigger [dbo].[btEMUCi] on [dbo].[bEMUC] for insert as
/*--------------------------------------------------------------
 * Created:  bc  08/11/99
 * Modified: TV 02/11/04 - 23061 added isnulls
 *			 GG 10/16/07 - #125791 - fix for DDDTShared
 *			 GF 07/19/2012 TK-16508 fix break start/stop messages and general cleanup
 *			 GF 05/05/2013 TFS-49039
 *
 *
 * Insert trigger for EMUC
 *
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int, @rcode int

declare @emco bCompany, @template varchar(10), @catgy bCat, @maxperpd bDollar, @minperpd bDollar,
        @daystart smalldatetime, @daystop smalldatetime, @br1start smalldatetime, @br1stop smalldatetime,
        @br2start smalldatetime, @br2stop smalldatetime, @br3start smalldatetime, @br3stop smalldatetime

declare @jcco bCompany, @validphasechars tinyint, @inputmask varchar(30), @pphase bPhase, @phasegroup bGroup

 select @numrows = @@rowcount
 if @numrows = 0 return
 set nocount on
    
    

    
   
    /* Validate Phase */
    /* JM 12-26-02 Ref Issue 18749 Rej 2 - Use same logic as bspJCPMValForEMUseAutoTemplate */
    if update(JCPhase)
    	begin
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
   				select @catgy = min(Category) from inserted where EMCo = @emco and AUTemplate = @template
   				while @catgy is not null
   					begin
   					/* Get Phase chunk to validate with */
   					select @pphase=substring(JCPhase,1,@validphasechars) + '%' from inserted
   					where EMCo = @emco and AUTemplate = @template and Category = @catgy
   					/* Validate the Phase chunk */
   					select TOP 1 @errmsg = Description from bJCPM where PhaseGroup = @phasegroup and Phase like @pphase
   					Group By PhaseGroup, Phase, Description
   					if @@rowcount = 0
   						begin
   						select @errmsg = 'Phase not setup in Phase Master.', @rcode = 1
   						goto error
   						end
   					select @catgy = min(Category) from inserted where EMCo = @emco and AUTemplate = @template and Category > @catgy
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
        select @catgy = min(Category) from inserted where EMCo = @emco and AUTemplate = @template
        while @catgy is not null
          begin
    	select @maxperpd = MaxPerPD, @minperpd = MinPerPd, @daystart = DayStartTime, @daystop = DayStopTime,
				@br1start = Br1StartTime, @br1stop = Br1StopTime,
				@br2start = Br2StartTime, @br2stop = Br2StopTime,
				@br3start = Br3StartTime, @br3stop = Br3StartTime
    	from inserted
    	where EMCo = @emco and AUTemplate = @template and Category = @catgy
    
    	if @maxperpd is not null and @minperpd is not null
    	  begin
            if @maxperpd < @minperpd
              begin
    	      select @errmsg = 'Maximum amount per period must be greater than the minimum amount per period '
    	      goto error
              end
    	  end
    
    
          select @catgy = min(Category) from inserted where EMCo = @emco and AUTemplate = @template and Category > @catgy
          end
        select @template = min(AUTemplate) from inserted where EMCo = @emco and AUTemplate > @template
        end
      select @emco = min(EMCo) from inserted where EMCo > @emco
      end
    
    
    return
    
    error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot insert into EMUC'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction

GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btEMUCu    Script Date: 8/28/99 9:37:23 AM ******/
CREATE trigger [dbo].[btEMUCu] on [dbo].[bEMUC] for update as
/*--------------------------------------------------------------
 * Created:  bc  08/11/99
 * Modified: TV 02/11/04 - 23061 added isnulls
 *			 GG 10/16/07 - #125791 - fix for DDDTShared
 *			 GF 07/19/2012 TK-16508 fix break start/stop messages and general cleanup
 *			 GF 05/09/2013 TFS-49039
 *
 *  Update trigger for EMUC
 *
 *--------------------------------------------------------------*/

declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int, @rcode int

declare @emco bCompany, @template varchar(10), @catgy bCat, @maxperpd bDollar, @minperpd bDollar,
        @daystart smalldatetime, @daystop smalldatetime, @br1start smalldatetime, @br1stop smalldatetime,
        @br2start smalldatetime, @br2stop smalldatetime, @br3start smalldatetime, @br3stop smalldatetime
    
declare @jcco bCompany, @validphasechars tinyint, @inputmask varchar(30), @pphase bPhase, @phasegroup bGroup

 select @numrows = @@rowcount
 if @numrows = 0 return
 set nocount on
    
      /* see if any fields have changed that is not allowed */
      if update(EMCo) or Update(AUTemplate) or Update(Category)
          begin
          select @validcnt = count(*) from inserted i
          JOIN deleted d ON d.EMCo = i.EMCo and d.AUTemplate=i.AUTemplate and d.Category = i.Category
    
          if @validcnt <> @numrows
              begin
              select @errmsg = 'Primary key fields may not be changed'
              GoTo error
              End
          End
    
    
    /* Validate Phase */
    /* JM 12-26-02 Ref Issue 18749 Rej 2 - Use same logic as bspJCPMValForEMUseAutoTemplate */
    if update(JCPhase)
    	begin
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
   				select @catgy = min(Category) from inserted where EMCo = @emco and AUTemplate = @template
   				while @catgy is not null
   					begin
   					/* Get Phase chunk to validate with */
   					select @pphase=substring(JCPhase,1,@validphasechars) + '%' from inserted
   					where EMCo = @emco and AUTemplate = @template and Category = @catgy
   					/* Validate the Phase chunk */
   					select TOP 1 @errmsg = Description from bJCPM where PhaseGroup = @phasegroup and Phase like @pphase
   					Group By PhaseGroup, Phase, Description
   					if @@rowcount = 0
   						begin
   						select @errmsg = 'Phase not setup in Phase Master.', @rcode = 1
   						goto error
   						end
   					select @catgy = min(Category) from inserted where EMCo = @emco and AUTemplate = @template and Category > @catgy
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
        select @catgy = min(Category) from inserted where EMCo = @emco and AUTemplate = @template
        while @catgy is not null
          begin
    	select @maxperpd = MaxPerPD, @minperpd = MinPerPd, @daystart = DayStartTime, @daystop = DayStopTime,
				@br1start = Br1StartTime, @br1stop = Br1StopTime,
				@br2start = Br2StartTime, @br2stop = Br2StopTime,
				@br3start = Br3StartTime, @br3stop = Br3StartTime
    	from inserted
    	where EMCo = @emco and AUTemplate = @template and Category = @catgy
    
    	if @maxperpd is not null and @minperpd is not null
    	  begin
            if @maxperpd < @minperpd
              begin
    	      select @errmsg = 'Maximum amount per period must be greater than the minimum amount per period '
    	      goto error
              end
    	  end
    

    
          select @catgy = min(Category) from inserted where EMCo = @emco and AUTemplate = @template and Category > @catgy
          end
        select @template = min(AUTemplate) from inserted where EMCo = @emco and AUTemplate > @template
        end
      select @emco = min(EMCo) from inserted where EMCo > @emco
      end
    
    
    return
    
    error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot update EMUC'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction

GO

CREATE UNIQUE CLUSTERED INDEX [biEMUC] ON [dbo].[bEMUC] ([EMCo], [AUTemplate], [Category]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMUC] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
