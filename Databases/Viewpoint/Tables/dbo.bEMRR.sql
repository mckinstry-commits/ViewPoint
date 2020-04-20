CREATE TABLE [dbo].[bEMRR]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[Category] [dbo].[bCat] NOT NULL,
[RevCode] [dbo].[bRevCode] NOT NULL,
[EMGroup] [dbo].[bGroup] NOT NULL,
[WorkUM] [dbo].[bUM] NULL,
[UpdtHrMeter] [dbo].[bYN] NOT NULL,
[PostWorkUnits] [dbo].[bYN] NOT NULL,
[AllowPostOride] [dbo].[bYN] NOT NULL,
[Rate] [dbo].[bDollar] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL,
[udSource] [varchar] (305) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biEMRR] ON [dbo].[bEMRR] ([EMCo], [Category], [RevCode], [EMGroup]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMRR] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btEMRRd    Script Date: 8/28/99 9:37:19 AM ******/
   
    CREATE  trigger [dbo].[btEMRRd] on [dbo].[bEMRR] for DELETE as
   
     

/***  basic declares for SQL Triggers ****/
    declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
            @errno tinyint, @audit bYN, @validcnt int, @nullcnt int
   
    /*--------------------------------------------------------------
     *
     *  Delete trigger for EMRR
     *  Created By: bc 10/27/98
     *  Modified by:  bc 1/12/99
     *					 TV 02/11/04 - 23061 added isnulls
     *
     *--------------------------------------------------------------*/
   
     /*** declare local variables ***/
   
    declare @count int, @revtemp varchar(10), @revcode varchar(10)
    select @numrows = @@rowcount, @count = 0
    if @numrows = 0 return
    set nocount on
   
   /* make sure that no revenue codes exist in relation to this category in the equipment override tables before deletion */
   select @count = count(*)
    from EMEM e, EMRC c, EMRH r, deleted d
    where 	e.EMCo  = d.EMCo and e.EMCo = r.EMCo and c.EMGroup = d.EMGroup and c.EMGroup = r.EMGroup and
   	e.Category = d.Category and c.RevCode = d.RevCode and c.RevCode = r.RevCode and
   	e.Equipment = r.Equipment
   
   if @count <> 0
   	begin
   	select @errmsg = 'Category/Revenue Code combination exists in Rates by Equipment'
   	goto error
   	end
   
   /* make sure that no revenue codes exist in relation to this category in the template tables before deletion */
   select @revtemp = min(e.RevTemplate), @revcode = min(e.RevCode)
   from EMTC e, deleted d
   where e.EMCo = d.EMCo and e.EMGroup = d.EMGroup and e.Category = d.Category and e.RevCode = d.RevCode
   
   /* Can't delete if EMTC entries exist for this category */
   if exists(select * from deleted d join EMTC r on d.EMCo = r.EMCo and r.Category = d.Category and
                                                    d.EMGroup = r.EMGroup and d.RevCode = r.RevCode)
      begin
      select @errmsg = 'Revenue Code exists in Revenue Template Category '
      goto error
      end
   
    /* delete all rev bdown codes for this rev code */
    delete bEMBG
    from bEMBG e, deleted d
    where e.EMCo = d.EMCo and e.Category = d.Category and e.EMGroup = d.EMGroup and e.RevCode = d.RevCode
   
   /* Audit insert */
   insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bEMRR','EM Company: ' + convert(char(3), d.EMCo) + ' Category: ' + d.Category +
       ' EMGroup: ' + convert(varchar(3),d.EMGroup) + ' RevCode: ' + d.RevCode,
       d.EMCo, 'D', null, null, null, getdate(), SUSER_SNAME()
   	from deleted d, EMCO e
       where d.EMCo = e.EMCo and e.AuditRevenueRateCateg = 'Y'
   
   
    return
   
    error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot delete from EMRR'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMRRi    Script Date: 8/28/99 9:37:19 AM ******/
   
    CREATE   trigger [dbo].[btEMRRi] on [dbo].[bEMRR] for insert as
   
     

/***  basic declares for SQL Triggers ****/
    declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
            @errno tinyint, @audit bYN, @validcnt int, @nullcnt int
   
    /*--------------------------------------------------------------
     *
     *  insert trigger for EMRR
     *  Created By: bc 10/27/98
     *  Modified by: danf 11/27/01 Corrected Error check on EMBG table
     *				 TV 02/11/04 - 23061 added isnulls
     *
     *--------------------------------------------------------------*/
   
     /*** declare local variables ***/
    declare @revbdowncode varchar(10), @bdowncodedesc varchar(30)
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   
   
   /* validate EMCo */
   select @validcnt = count(*) from bEMCO e join inserted i on e.EMCo = i.EMCo
   if @validcnt <> @numrows
     begin
     select @errmsg = 'Invalid EM Company '
     goto error
     end
   
   /* validate EMGroup */
   select @validcnt = count(*) from bHQGP e join inserted i on e.Grp = i.EMGroup
   if @validcnt <> @numrows
     begin
     select @errmsg = 'Invalid EM Group '
     goto error
     end
   
   /* validate Category */
   select @validcnt = count(*) from bEMCM e join inserted i on e.EMCo = i.EMCo and e.Category = i.Category
   if @validcnt <> @numrows
     begin
     select @errmsg = 'Invalid Category '
     goto error
     end
   
   /* validate RevCode */
   select @validcnt = count(*) from bEMRC e join inserted i on e.EMGroup = i.EMGroup and e.RevCode = i.RevCode
   if @validcnt <> @numrows
     begin
     select @errmsg = 'Invalid Revenue Code '
     goto error
     end
   
   
   /* validate WorkUM */
   select @validcnt = count(*) from bHQUM e join inserted i on e.UM = i.WorkUM
   select @nullcnt = count(*) from inserted i where i.WorkUM is null
   if @validcnt + @nullcnt <> @numrows
     begin
     select @errmsg = 'Invalid Work Unit of Measure '
     goto error
     end
   
   /* validate UpdateHourMeter */
   select @validcnt = count(*) from inserted i where UpdtHrMeter in('Y','N')
   if @validcnt <> @numrows
     begin
     select @errmsg = 'Missing Update Hour Meter Flag '
     goto error
     end
   
   /* validate PostWorkUnits */
   select @validcnt = count(*) from inserted i where PostWorkUnits in('Y','N')
   if @validcnt <> @numrows
     begin
     select @errmsg = 'Missing Post Work Units Flag '
     goto error
     end
   
   /* validate AllowPostOride */
   select @validcnt = count(*) from inserted i where AllowPostOride in('Y','N')
   if @validcnt <> @numrows
     begin
     select @errmsg = 'Missing Allow posting overrate Flag '
     goto error
     end
   
   /* snag the default revenue breakdown code rom EM Company file */
    select @revbdowncode = UseRevBkdwnCodeDefault
    from EMCO e, inserted i
    where e.EMCo = i.EMCo
   
    if @revbdowncode is null
      begin
      select @errmsg = 'Missing default revenue breakdown code in Company form!'
      goto error
      end
   
   /* the revbdowncode description for new EMBG entries */
    select @bdowncodedesc = Description
    from EMRT e, inserted i
    where e.EMGroup = i.EMGroup and e.RevBdownCode = @revbdowncode
   
   /* insert default Bdown code into EMBG when a new entry is made into EMRR */
	insert into bEMBG (EMCo, EMGroup, Category, RevCode, RevBdownCode, Description, Rate)
	select i.EMCo, i.EMGroup, i.Category, i.RevCode, @revbdowncode, @bdowncodedesc, i.Rate
	from inserted i
	if @@rowcount <> @numrows
		begin
		select @errmsg = 'Errors updating the revenue breakdown code'
		goto error
		end
   
   /* Audit insert */
   insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bEMRR','EM Company: ' + convert(char(3), i.EMCo) + ' Category: ' + i.Category +
       ' EMGroup: ' + convert(varchar(3),i.EMGroup) + ' RevCode: ' + i.RevCode,
       i.EMCo, 'A', null, null, null, getdate(), SUSER_SNAME()
   	from inserted i, EMCO e
       where i.EMCo = e.EMCo and e.AuditRevenueRateCateg = 'Y'
   
   
    return
   
    error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot insert into EMRR'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
  
 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMRRu    Script Date: 8/28/99 9:37:19 AM ******/
   
    CREATE   trigger [dbo].[btEMRRu] on [dbo].[bEMRR] for update as
   
     

/***  basic declares for SQL Triggers ****/
    declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
            @errno tinyint, @audit bYN, @validcnt int, @nullcnt int
   
    /*--------------------------------------------------------------
     *
     *  update trigger for EMRR
     *  Created By: bc 10/12/98
     *  Modified by:  TV 02/11/04 - 23061 added isnulls
     *
     *
     *--------------------------------------------------------------*/
   
     /*** declare local variables ***/
    declare @revbdowncode varchar(10), @bdowncodedesc varchar(30), @rateflag bYN, @rate bDollar,
    	 @emco bCompany, @emgroup bGroup, @catgy varchar(10), @revcode varchar(10)
   
   
    select @numrows = @@rowcount
    if @numrows = 0 return
   
    set nocount on
   
   
   if update(EMCo) or update(EMGroup) or update(Category) or update(RevCode)
     begin
     select @validcnt = count(*) from inserted i join deleted d on i.EMCo = d.EMCo and i.EMGroup = d.EMGroup and i.Category = i.Category and i.RevCode = d.RevCode
     if @validcnt <> @numrows
       begin
       select @errmsg = 'Cannot change key fields '
       goto error
       end
     end
   
   
   /* validate WorkUM */
   select @validcnt = count(*) from bHQUM e join inserted i on e.UM = i.WorkUM
   select @nullcnt = count(*) from inserted i where i.WorkUM is null
   if @validcnt + @nullcnt <> @numrows
     begin
     select @errmsg = 'Invalid Work Unit of Measure '
     goto error
     end
   
   /* validate UpdateHourMeter */
   select @validcnt = count(*) from inserted i where UpdtHrMeter in('Y','N')
   if @validcnt <> @numrows
     begin
     select @errmsg = 'Missing Update Hour Meter Flag '
     goto error
     end
   
   /* validate PostWorkUnits */
   select @validcnt = count(*) from inserted i where PostWorkUnits in('Y','N')
   if @validcnt <> @numrows
     begin
     select @errmsg = 'Missing Post Work Units Flag '
     goto error
     end
   
   /* validate AllowPostOride */
   select @validcnt = count(*) from inserted i where AllowPostOride in('Y','N')
   if @validcnt <> @numrows
     begin
     select @errmsg = 'Missing Allow posting overrate Flag '
     goto error
     end
   
   
   if update(Rate)
   /* update lone Revenue Breakdown Code in EMBG when a change is made to the rate in EMRR */
     begin
     select @emco = min(EMCo)
     from inserted
     while @emco is not null
       begin
       select @emgroup = min(EMGroup)
       from inserted
       where EMCo = @emco
       while @emgroup is not null
         begin
         select @catgy = min(Category)
         from inserted
         where EMCo = @emco and EMGroup = @emgroup
         while @catgy is not null
           begin
           select @revcode = RevCode
           from inserted
           where EMCo = @emco and EMGroup = @emgroup and Category = @catgy
           while @revcode is not null
             begin
             select @rate = Rate
             from inserted
             where EMCo = @emco and EMGroup = @emgroup and Category = @catgy and RevCode = @revcode
   
             select @validcnt = count(*)
             from bEMBG
             where EMCo = @emco and EMGroup = @emgroup and Category = @catgy and RevCode = @revcode
   
             /* do not update EMBG if more than one revenue breakdown code exists */
             if @validcnt = 1
               begin
               update bEMBG
               set Rate = @rate
               where EMCo = @emco and EMGroup = @emgroup and Category = @catgy and RevCode = @revcode
               end
   
             select @revcode = min(RevCode)
             from inserted
             where EMCo = @emco and EMGroup = @emgroup and Category = @catgy and RevCode > @revcode
             end
   
           select @catgy = min(Category)
           from inserted
           where EMCo = @emco and EMGroup = @emgroup and Category > @catgy
           end
   
         select @emgroup = min(EMGroup)
         from inserted
         where EMCo = @emco and EMGroup > @emgroup
         end
   
       select @emco = min(EMCo)
       from inserted
       where EMCo > @emco
       end
   
   end
   
    /* Audit inserts */
    if not exists (select * from inserted i, EMCO e
    	where i.EMCo = e.EMCo and e.AuditRevenueRateCateg = 'Y')
    	return
   
    insert into bHQMA select 'bEMRR', 'EM Company: ' + convert(char(3), i.EMCo) + ' Category: ' + i.Category +
       ' EMGroup: ' + convert(varchar(3),i.EMGroup) + ' RevCode: ' + i.RevCode,
       i.EMCo, 'C', 'WorkUM', d.WorkUM, i.WorkUM, getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and i.Category = d.Category and i.EMGroup = d.EMGroup and i.RevCode = d.RevCode and i.WorkUM <> d.WorkUM and
       e.EMCo = i.EMCo and e.AuditRevenueRateCateg = 'Y'
   
    insert into bHQMA select 'bEMRR', 'EM Company: ' + convert(char(3), i.EMCo) + ' Category: ' + i.Category +
       ' EMGroup: ' + convert(varchar(3),i.EMGroup) + ' RevCode: ' + i.RevCode,
       i.EMCo, 'C', 'UpdtHrMeter', d.UpdtHrMeter, i.UpdtHrMeter, getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and i.Category = d.Category and i.EMGroup = d.EMGroup and i.RevCode = d.RevCode and i.UpdtHrMeter <> d.UpdtHrMeter and
       e.EMCo = i.EMCo and e.AuditRevenueRateCateg = 'Y'
   
    insert into bHQMA select 'bEMRR', 'EM Company: ' + convert(char(3), i.EMCo) + ' Category: ' + i.Category +
       ' EMGroup: ' + convert(varchar(3),i.EMGroup) + ' RevCode: ' + i.RevCode,
       i.EMCo, 'C', 'PostWorkUnits', d.PostWorkUnits, i.PostWorkUnits, getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and i.Category = d.Category and i.EMGroup = d.EMGroup and i.RevCode = d.RevCode and i.PostWorkUnits <> d.PostWorkUnits and
       e.EMCo = i.EMCo and e.AuditRevenueRateCateg = 'Y'
   
    insert into bHQMA select 'bEMRR', 'EM Company: ' + convert(char(3), i.EMCo) + ' Category: ' + i.Category +
       ' EMGroup: ' + convert(varchar(3),i.EMGroup) + ' RevCode: ' + i.RevCode,
       i.EMCo, 'C', 'AllowPostOride', d.AllowPostOride, i.AllowPostOride, getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and i.Category = d.Category and i.EMGroup = d.EMGroup and i.RevCode = d.RevCode and i.AllowPostOride <> d.AllowPostOride and
       e.EMCo = i.EMCo and e.AuditRevenueRateCateg = 'Y'
   
    insert into bHQMA select 'bEMRR', 'EM Company: ' + convert(char(3), i.EMCo) + ' Category: ' + i.Category +
       ' EMGroup: ' + convert(varchar(3),i.EMGroup) + ' RevCode: ' + i.RevCode,
       i.EMCo, 'C', 'Rate', d.Rate, i.Rate, getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and i.Category = d.Category and i.EMGroup = d.EMGroup and i.RevCode = d.RevCode and i.Rate <> d.Rate and
       e.EMCo = i.EMCo and e.AuditRevenueRateCateg = 'Y'
   
   
    return
   
    error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot update EMRR'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
  
 



GO

GO

GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMRR].[UpdtHrMeter]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMRR].[PostWorkUnits]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMRR].[AllowPostOride]'
GO
