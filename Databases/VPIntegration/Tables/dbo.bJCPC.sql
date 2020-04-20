CREATE TABLE [dbo].[bJCPC]
(
[PhaseGroup] [tinyint] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[CostType] [dbo].[bJCCType] NOT NULL,
[BillFlag] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[ItemUnitFlag] [dbo].[bYN] NOT NULL,
[PhaseUnitFlag] [dbo].[bYN] NOT NULL,
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btJCPCd    Script Date: 8/28/99 9:37:47 AM ******/
   CREATE trigger [dbo].[btJCPCd] on [dbo].[bJCPC] for DELETE as 
   
    

/***  basic declares for SQL Triggers ****/
   declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15), 
           @errno tinyint, @audit bYN, @validcnt int, @validcnt2 int
   
   /*-------------------------------------------------------------- 
    *
    *  Delete trigger for JCPC
    *  Created By: 
	*  Modified By:	GP 11/14/2008 - Issue 130925, add auditing.
    *  Date:       
    *
    *
    *--------------------------------------------------------------*/
    select @numrows = @@rowcount 
    if @numrows = 0 return
    set nocount on
   
   /* Check bJCCH for detail */
   
   /*if exists(select * from deleted d JOIN bJCCH o ON
    d.PhaseGroup = o.PhaseGroup
    and d.Phase = o.Phase
    and d.CostType = o.CostType)
      begin
      select @errmsg = 'Entries exist in JC Cost Header'
      goto error
      end*/
   
	-------------------
	-- HQMA Auditing --
	-------------------
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select distinct 'bJCPC', ' Key: PhaseGroup ' + isnull(convert(varchar(3),d.PhaseGroup),'') + '/Phase ' + isnull(convert(varchar(20),d.Phase),'') + '/CostType ' +
		isnull(convert(varchar(3), d.CostType),''), null, 'D', null, null, null, getdate(), SUSER_SNAME()
	from deleted d
	join bHQCO h on h.PhaseGroup = d.PhaseGroup
	join bJCCO c on c.JCCo = h.HQCo
	where c.AuditPhaseMaster = 'Y'
   

   return
      
   error:
      select @errmsg = @errmsg + ' - cannot delete from JC Phase Cost Types'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






/****** Object:  Trigger dbo.btJCPCi    Script Date: 8/28/99 9:37:47 AM ******/
   CREATE  trigger [dbo].[btJCPCi] on [dbo].[bJCPC] for INSERT as 
   
    

/***  basic declares for SQL Triggers ****/
   declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15), 
           @errno tinyint, @audit bYN, @validcnt int, @validcnt2 int
   
   /*-------------------------------------------------------------- 
    *
    *  Insert trigger for JCPC
    *  Created By: 
    *  Modified Date:	DanF 01/03/2005 - Issue 30134 Added Phase Validation
	*					GP 11/14/2008 - Issue 130925, add auditing.
    *
    *
    *--------------------------------------------------------------*/
    select @numrows = @@rowcount 
    if @numrows = 0 return
    set nocount on
   
   /* Validate UM */
   
   select @validcnt = count(*) from bHQUM r with (nolock)
	JOIN inserted i ON
    i.UM = r.UM
   
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Unit of Measure is Invalid '
      goto error
      end
   
   /* Validate CostType */
   
   select @validcnt = count(*) from dbo.bJCCT r with (nolock)
	JOIN inserted i ON
    i.PhaseGroup = r.PhaseGroup
    and i.CostType = r.CostType
   
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Cost Type is Invalid '
      goto error
      end

   -- validate JCPM
   SELECT @validcnt=count(*) from dbo.bJCPM p with (nolock) 
   JOIN inserted i ON i.PhaseGroup=p.PhaseGroup and i.Phase=p.Phase
   IF @validcnt<>@numrows
      	BEGIN
      	SELECT @errmsg = 'Invalid Phase'
      	GOTO error
      	END
   
	-------------------
	-- HQMA Auditing --
	-------------------
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select distinct 'bJCPC', ' Key: PhaseGroup ' + isnull(convert(varchar(3),i.PhaseGroup),'') + '/Phase ' + isnull(convert(varchar(20),i.Phase),'') + '/CostType ' +
		isnull(convert(varchar(3), i.CostType), ''), null, 'A', null, null, null, getdate(), SUSER_SNAME()
	from inserted i
	join bHQCO h on h.PhaseGroup = i.PhaseGroup
	join bJCCO c on c.JCCo = h.HQCo
	where c.AuditPhaseMaster = 'Y'

   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot insert into JC Phase Cost Types'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btJCPCu    Script Date: 8/28/99 9:37:47 AM ******/
   CREATE  trigger [dbo].[btJCPCu] on [dbo].[bJCPC] for UPDATE as 
   
    

/***  basic declares for SQL Triggers ****/
   declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15), 
           @errno tinyint, @audit bYN, @validcnt int, @validcnt2 int
   
   /*-------------------------------------------------------------- 
    *
    *  Update trigger for JCPC
    *  Created By: 
	*  Modified By:	GP 11/14/2008 - Issue 130925, add auditing.
    *  Date:       
    *
    *
    *--------------------------------------------------------------*/
    select @numrows = @@rowcount 
    if @numrows = 0 return
    set nocount on
   
   /* Validate UM */
   
   if update(UM)
      begin
      select @validcnt = count(*) from bHQUM r JOIN inserted i ON
       i.UM = r.UM
   
      if @validcnt <> @numrows
         begin
         select @errmsg = 'Unit of Measure is Invalid'
   
         goto error
         end
      end
   
   /* Validate CostType */
   
   if update(CostType)
      begin
      select @validcnt = count(*) from bJCCT r JOIN inserted i ON
       i.PhaseGroup = r.PhaseGroup
       and i.CostType = r.CostType
   
      if @validcnt <> @numrows
         begin
         select @errmsg = 'Cost Type is Invalid'
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
   
   /* check for changes to CostType */
   if update(CostType)
      begin
      select @errmsg = 'Cannot change Cost Type'
      goto error
      end

	-------------------
	-- HQMA Auditing --
	-------------------
	if update(Phase)
	begin
		insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
			select distinct 'bJCPC', ' Key: PhaseGroup ' + isnull(convert(varchar(3),i.PhaseGroup),'') + '/Phase ' + isnull(convert(varchar(20),i.Phase),'') + '/CostType ' +
			isnull(convert(varchar(3), i.CostType), ''), null, 'C', 'Phase', d.Phase, i.Phase, getdate(), SUSER_SNAME()
		from inserted i join deleted d on d.PhaseGroup = i.PhaseGroup and d.Phase = i.Phase and d.CostType = i.CostType
		join bHQCO h on h.PhaseGroup = i.PhaseGroup
		join bJCCO c on c.JCCo = h.HQCo
		where c.AuditPhaseMaster = 'Y'
	end

	if update(CostType)
	begin
		insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
			select distinct 'bJCPC', ' Key: PhaseGroup ' + isnull(convert(varchar(3),i.PhaseGroup),'') + '/Phase ' + isnull(convert(varchar(20),i.Phase),'') + '/CostType ' +
			isnull(convert(varchar(3), i.CostType), ''), null, 'C', 'CostType', d.CostType, i.CostType, getdate(), SUSER_SNAME()
		from inserted i join deleted d on d.PhaseGroup = i.PhaseGroup and d.Phase = i.Phase and d.CostType = i.CostType
		join bHQCO h on h.PhaseGroup = i.PhaseGroup
		join bJCCO c on c.JCCo = h.HQCo
		where c.AuditPhaseMaster = 'Y'
	end

	if update(BillFlag)
	begin
		insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
			select distinct 'bJCPC', ' Key: PhaseGroup ' + isnull(convert(varchar(3),i.PhaseGroup),'') + '/Phase ' + isnull(convert(varchar(20),i.Phase),'') + '/CostType ' +
			isnull(convert(varchar(3), i.CostType), ''), null, 'C', 'BillFlag', d.BillFlag, i.BillFlag, getdate(), SUSER_SNAME()
		from inserted i join deleted d on d.PhaseGroup = i.PhaseGroup and d.Phase = i.Phase and d.CostType = i.CostType
		join bHQCO h on h.PhaseGroup = i.PhaseGroup
		join bJCCO c on c.JCCo = h.HQCo
		where c.AuditPhaseMaster = 'Y'
	end

	if update(UM)
	begin
		insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
			select distinct 'bJCPC', ' Key: PhaseGroup ' + isnull(convert(varchar(3),i.PhaseGroup),'') + '/Phase ' + isnull(convert(varchar(20),i.Phase),'') + '/CostType ' +
			isnull(convert(varchar(3), i.CostType), ''), null, 'C', 'UM', d.UM, i.UM, getdate(), SUSER_SNAME()
		from inserted i join deleted d on d.PhaseGroup = i.PhaseGroup and d.Phase = i.Phase and d.CostType = i.CostType
		join bHQCO h on h.PhaseGroup = i.PhaseGroup
		join bJCCO c on c.JCCo = h.HQCo
		where c.AuditPhaseMaster = 'Y'
	end

	if update(ItemUnitFlag)
	begin
		insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
			select distinct 'bJCPC', ' Key: PhaseGroup ' + isnull(convert(varchar(3),i.PhaseGroup),'') + '/Phase ' + isnull(convert(varchar(20),i.Phase),'') + '/CostType ' +
			isnull(convert(varchar(3), i.CostType), ''), null, 'C', 'ItemUnitFlag', d.ItemUnitFlag, i.ItemUnitFlag, getdate(), SUSER_SNAME()
		from inserted i join deleted d on d.PhaseGroup = i.PhaseGroup and d.Phase = i.Phase and d.CostType = i.CostType
		join bHQCO h on h.PhaseGroup = i.PhaseGroup
		join bJCCO c on c.JCCo = h.HQCo
		where c.AuditPhaseMaster = 'Y'
	end

	if update(PhaseUnitFlag)
	begin
		insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
			select distinct 'bJCPC', ' Key: PhaseGroup ' + isnull(convert(varchar(3),i.PhaseGroup),'') + '/Phase ' + isnull(convert(varchar(20),i.Phase),'') + '/CostType ' +
			isnull(convert(varchar(3), i.CostType), ''), null, 'C', 'PhaseUnitFlag', d.PhaseUnitFlag, i.PhaseUnitFlag, getdate(), SUSER_SNAME()
		from inserted i join deleted d on d.PhaseGroup = i.PhaseGroup and d.Phase = i.Phase and d.CostType = i.CostType
		join bHQCO h on h.PhaseGroup = i.PhaseGroup
		join bJCCO c on c.JCCo = h.HQCo
		where c.AuditPhaseMaster = 'Y'
	end
   

   return
   
   error:
      select @errmsg = @errmsg + ' - cannot update JC Phase Cost Types'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biJCPC] ON [dbo].[bJCPC] ([PhaseGroup], [Phase], [CostType]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCPC].[ItemUnitFlag]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCPC].[PhaseUnitFlag]'
GO
