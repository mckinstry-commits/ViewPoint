CREATE TABLE [dbo].[bJCPM]
(
[PhaseGroup] [tinyint] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[ProjMinPct] [dbo].[bPct] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btJCPMd    Script Date: 8/28/99 9:37:47 AM ******/
   CREATE trigger [dbo].[btJCPMd] on [dbo].[bJCPM] for DELETE as
    

/***  basic declares for SQL Triggers ****/
   declare @numrows int, @errmsg varchar(255), @validcnt int
   /*--------------------------------------------------------------
    *
    *  Delete trigger for JCPM
    *  Created By:
    *  Modified By DANF 03/16/00 Changed Check from JCJP table to JCPC table
    *				GF 02/10/2004 - #22617 added check for JCDO when deleting phase
	*				GP 11/14/2008 - Issue 130925, add auditing.
	*
    *  Date:
    *
    *
    *--------------------------------------------------------------*/
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   -- Check bJCPC for detail
   if exists(select * from deleted d JOIN bJCPC o ON
   		d.PhaseGroup = o.PhaseGroup and d.Phase = o.Phase)
      begin
      select @errmsg = 'Entries exist in JC Phase Cost Type'
      goto error
      end
   
   -- check bJCDO for phase
   if exists(select * from deleted d join bJCDO o on d.PhaseGroup=o.PhaseGroup and d.Phase=o.Phase)
      begin
      select @errmsg = 'Entries exist in JC Department Master Phase Overrides'
      goto error
      end
   
	-------------------
	-- HQMA Auditing --
	-------------------
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select distinct 'bJCPM', ' Key: PhaseGroup ' + isnull(convert(varchar(3),d.PhaseGroup),'') + '/ Phase ' + isnull(convert(varchar(20),d.Phase),''), 
		null, 'D', null, null, null, getdate(), SUSER_SNAME()
	from deleted d
	join bHQCO h on h.PhaseGroup = d.PhaseGroup
	join bJCCO c on c.JCCo = h.HQCo
	where c.AuditPhaseMaster = 'Y' 

	
   return
      
   error:
      select @errmsg = @errmsg + ' - cannot delete from JC Phase Master'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btJCPMi    Script Date: 8/28/99 9:37:47 AM ******/
   CREATE trigger [dbo].[btJCPMi] on [dbo].[bJCPM] for INSERT as 
    

/***  basic declares for SQL Triggers ****/
   declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15), 
           @errno tinyint, @audit bYN, @validcnt int, @validcnt2 int
   
   /*-------------------------------------------------------------- 
    *
    *  Insert trigger for JCPM
    *  Created By:	LM
	*  Modified By:	GP 11/14/2008 - Issue 130925, add auditing.
    *  Date:       11/26/96  
    *
    *
    *--------------------------------------------------------------*/
    select @numrows = @@rowcount 
    if @numrows = 0 return
    set nocount on
   
   /* Validate PhaseGroup */
   
   select @validcnt = count(*) from bHQGP r JOIN inserted i ON
    i.PhaseGroup = r.Grp
   
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Phase Group is Invalid '
      goto error
      end
   
	-------------------
	-- HQMA Auditing --
	-------------------
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select distinct 'bJCPM', ' Key: PhaseGroup ' + isnull(convert(varchar(3),i.PhaseGroup),'') + '/ Phase ' + isnull(convert(varchar(20),i.Phase),''), 
		null, 'A', null, null, null, getdate(), SUSER_SNAME()
	from inserted i
	join bHQCO h on h.PhaseGroup = i.PhaseGroup
	join bJCCO c on c.JCCo = h.HQCo
	where c.AuditPhaseMaster = 'Y'
  
   
    return
   
    error:
		select @errmsg = @errmsg + ' - cannot insert into JCPM'
		RAISERROR(@errmsg, 11, -1);
		rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btJCPMu    Script Date: 8/28/99 9:37:47 AM ******/
   CREATE trigger [dbo].[btJCPMu] on [dbo].[bJCPM] for UPDATE as 
    

/***  basic declares for SQL Triggers ****/
   declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15), 
           @errno tinyint, @audit bYN, @validcnt int, @validcnt2 int
   
   /*-------------------------------------------------------------- 
    *
    *  Update trigger for JCPM
    *  Created By: 
	*  Modified By:	GP 11/14/2008 - Issue 130925, add auditing. 
    *  Date:       
    *
    *
    *--------------------------------------------------------------*/
    select @numrows = @@rowcount 
    if @numrows = 0 return
    set nocount on
   
   /* Validate PhaseGroup */
   
   if update(PhaseGroup)
      begin
      select @validcnt = count(*) from bHQGP r JOIN inserted i ON
       i.PhaseGroup = r.Grp
   
      if @validcnt <> @numrows
         begin
         select @errmsg = 'Phase Group is Invalid '
         goto error
         end
      end
   
   
   
   /* check for changes to PhaseGroup */
   if update(PhaseGroup)
      begin
      select @errmsg = 'Cannot change Phase Group'
      goto error
      end
   
   /* check for changes to Phase */
   if update(Phase)
   
      begin
      select @errmsg = 'Cannot change Phase'
      goto error
      end
   
	-------------------
	-- HQMA Auditing --
	-------------------
	if update(Phase)
	begin
		insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
			select distinct 'bJCPM', ' Key: PhaseGroup ' + isnull(convert(varchar(3),i.PhaseGroup),'') + '/ Phase ' + isnull(convert(varchar(20),i.Phase),''), 
			null, 'C', 'Phase', d.Phase, i.Phase, getdate(), SUSER_SNAME()
		from inserted i join deleted d on d.PhaseGroup = i.PhaseGroup and d.Phase = i.Phase
		join bHQCO h on h.PhaseGroup = i.PhaseGroup
		join bJCCO c on c.JCCo = h.HQCo
		where c.AuditPhaseMaster = 'Y'
	end

	if update(Description)
	begin
		insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
			select distinct 'bJCPM', ' Key: PhaseGroup ' + isnull(convert(varchar(3),i.PhaseGroup),'') + '/ Phase ' + isnull(convert(varchar(20),i.Phase),''), 
			null, 'C', 'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
		from inserted i join deleted d on d.PhaseGroup = i.PhaseGroup and d.Phase = i.Phase
		join bHQCO h on h.PhaseGroup = i.PhaseGroup
		join bJCCO c on c.JCCo = h.HQCo
		where c.AuditPhaseMaster = 'Y'
	end

	if update(ProjMinPct)
	begin
		insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
			select distinct 'bJCPM', ' Key: PhaseGroup ' + isnull(convert(varchar(3),i.PhaseGroup),'') + '/ Phase ' + isnull(convert(varchar(20),i.Phase),''), 
			null, 'C', 'ProjMinPct', convert(varchar(12), d.ProjMinPct), convert(varchar(12), i.ProjMinPct), getdate(), SUSER_SNAME()
		from inserted i join deleted d on d.PhaseGroup = i.PhaseGroup and d.Phase = i.Phase
		join bHQCO h on h.PhaseGroup = i.PhaseGroup
		join bJCCO c on c.JCCo = h.HQCo
		where c.AuditPhaseMaster = 'Y'
	end

   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot update JC Phase Master'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJCPM] ([KeyID]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biJCPMNoGroup] ON [dbo].[bJCPM] ([Phase]) INCLUDE ([Description]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biJCPM] ON [dbo].[bJCPM] ([PhaseGroup], [Phase]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
