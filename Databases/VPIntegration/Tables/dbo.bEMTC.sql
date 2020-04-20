CREATE TABLE [dbo].[bEMTC]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[RevTemplate] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Category] [dbo].[bCat] NOT NULL,
[RevCode] [dbo].[bRevCode] NOT NULL,
[EMGroup] [dbo].[bGroup] NOT NULL,
[AllowOrideFlag] [char] (1) COLLATE Latin1_General_BIN NULL,
[Rate] [dbo].[bDollar] NOT NULL,
[DiscFromStdRate] [dbo].[bPct] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btEMTCd    Script Date: 8/28/99 9:37:22 AM ******/
   
   
     CREATE  trigger [dbo].[btEMTCd] on [dbo].[bEMTC] for DELETE as
   
      

/***  basic declares for SQL Triggers ****/
     declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
             @errno tinyint, @audit bYN, @validcnt int, @nullcnt int
   
     /*--------------------------------------------------------------
      *
      *  Delete trigger for EMTC
      *  Created By: bc 10/30/98
      *  Modified by: TV 02/11/04 - 23061 added isnulls
      *
      *
      *--------------------------------------------------------------*/
   
   
      /*** declare local variables ***/
   
     declare @count int
     select @numrows = @@rowcount, @count = 0
     if @numrows = 0 return
     set nocount on
   
   /* Can't delete if EMTE entries exist for equipment in this category with this revenue code */
    select @count = count(*)
     from EMEM e, EMRC c, EMTE r, deleted d
     where e.EMCo  = d.EMCo and e.EMCo = r.EMCo and c.EMGroup = d.EMGroup and c.EMGroup = r.EMGroup and
    	    e.Category = d.Category and c.RevCode = d.RevCode and c.RevCode = r.RevCode and
    	    e.Equipment = r.Equipment and r.RevTemplate = d.RevTemplate
     if @count <> 0
    	begin
    	select @errmsg = 'Template/Category/Revenue Code combination exists in Rates by Equipment template'
    	goto error
    	end
   
     /* delete all rev bdown codes for this rev code */
     delete bEMTD
     from bEMTD e, deleted d
     where e.EMCo = d.EMCo and e.RevTemplate = d.RevTemplate and e.Category = d.Category and
     	e.EMGroup = d.EMGroup and e.RevCode = d.RevCode
   
   
   /* Audit insert */
   insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bEMTC','EM Company: ' + convert(char(3), d.EMCo) + ' Category: ' + d.Category + ' Revtemplate: ' + d.RevTemplate +
       ' EMGroup: ' + convert(varchar(3),d.EMGroup) + ' RevCode: ' + d.RevCode,
       d.EMCo, 'D', null, null, null, getdate(), SUSER_SNAME()
   	from deleted d, EMCO e
       where d.EMCo = e.EMCo and e.AuditRevenueRateCateg = 'Y'
   
   
     return
   
     error:
        select @errmsg = isnull(@errmsg,'') + ' - cannot delete from EMTC'
        RAISERROR(@errmsg, 11, -1);
        rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMTCi    Script Date: 8/28/99 9:37:22 AM ******/
   
    CREATE   trigger [dbo].[btEMTCi] on [dbo].[bEMTC] for insert as
   
     

/***  basic declares for SQL Triggers ****/
    declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
            @errno tinyint, @audit bYN, @validcnt int, @nullcnt int
   
    /*--------------------------------------------------------------
     *
     *  insert trigger for EMTC
     *  Created By: bc 10/27/98
     *  Modified by: TV 02/11/04 - 23061 added isnulls
	 *				 GP	06/03/2008	Issue #124676 - Add check for CopyFlag value before inserting default
	 *									record into bEMTD.
     *
     *
     *--------------------------------------------------------------*/
   
     /*** declare local variables ***/
    declare @revbdowncode varchar(10), @bdowncodedesc varchar(30), @copy_flag bYN, @type_flag char(1)
   
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
   
   /* validate RevTemplate */
   select @validcnt = count(*) from bEMTH e join inserted i on e.EMCo = i.EMCo and e.RevTemplate = i.RevTemplate
   if @validcnt <> @numrows
     begin
     select @errmsg = 'Invalid Revenue template '
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
   
   /* validate AllowPostOride */
   select @validcnt = count(*) from inserted i where AllowOrideFlag in('Y','N')
   if @validcnt <> @numrows
     begin
     select @errmsg = 'Missing Allow posting overide Flag '
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
   
   /* the revbdowncode description for new EMTD entries */
    select @bdowncodedesc = Description
    from EMRT e, inserted i
    where e.EMGroup = i.EMGroup and e.RevBdownCode = @revbdowncode
   
	/* get the CopyFlag value so we know if we should insert a new record into EMTF below */
	select @copy_flag = CopyFlag
	from bEMTH e join inserted i 
	on e.EMCo = i.EMCo and e.RevTemplate = i.RevTemplate

   /* acquire the type flag from EMTH so we know whether or not to add row to breakdown code */
   select @type_flag = TypeFlag
   from EMTH e, inserted i
   where e.EMCo = i.EMCo and e.RevTemplate = i.RevTemplate
   
   if @type_flag = 'O' and @copy_flag = 'N'
   begin
   /* insert default Bdown code into EMTD when a new entry is made into EMTC */
    	insert into bEMTD (EMCo, EMGroup, RevTemplate, Category, RevCode, RevBdownCode, Description, Rate)
    	select i.EMCo, i.EMGroup, i.RevTemplate, i.Category, i.RevCode, @revbdowncode, @bdowncodedesc, i.Rate
    	from inserted i
   
    	if @@rowcount <> 1
    		begin
    		select @errmsg = 'Errors updating the revenue breakdown code'
    		goto error
    		end
   end
   
   
   /* Audit insert */
   insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bEMTC','EM Company: ' + convert(char(3), i.EMCo) + ' Category: ' + i.Category + ' Revtemplate: ' + i.RevTemplate +
       ' EMGroup: ' + convert(varchar(3),i.EMGroup) + ' RevCode: ' + i.RevCode,
       i.EMCo, 'A', null, null, null, getdate(), SUSER_SNAME()
   	from inserted i, EMCO e
       where i.EMCo = e.EMCo and e.AuditRevenueRateCateg = 'Y'
   
   
    return
   
    error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot insert into EMTC'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMTCu    Script Date: 8/28/99 9:37:22 AM ******/
   
    CREATE   trigger [dbo].[btEMTCu] on [dbo].[bEMTC] for update as
   
     

/***  basic declares for SQL Triggers ****/
    declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
            @errno tinyint, @audit bYN, @validcnt int, @nullcnt int
   
    /*--------------------------------------------------------------
     *
     *  update trigger for EMTC
     *  Created By: bc 05/20/99
     *  Modified by: TV 02/11/04 - 23061 added isnulls
     *
     *
     *--------------------------------------------------------------*/
   
     /*** declare local variables ***/
    declare @revbdowncode varchar(10), @bdowncodedesc varchar(30), @type_flag char(1), @rate bDollar,
    	 @emco bCompany, @emgroup bGroup, @revtemp varchar(10), @catgy varchar(10), @revcode varchar(10)
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   
   if update(EMCo) or update(EMGroup) or update(RevTemplate) or update(Category) or update(RevCode)
     begin
     select @validcnt = count(*) from inserted i join deleted d on
            i.EMCo = d.EMCo and i.EMGroup = d.EMGroup and i.RevTemplate = d.RevTemplate and i.Category = i.Category and i.RevCode = d.RevCode
     if @validcnt <> @numrows
       begin
       select @errmsg = 'Cannot change key fields '
       goto error
       end
     end
   
   /* validate AllowOrideFlag */
   if update(AllowOrideFlag)
   begin
   select @validcnt = count(*) from inserted i where AllowOrideFlag in('Y','N')
   if @validcnt <> @numrows
     begin
     select @errmsg = 'Missing Allow posting overide Flag '
     goto error
     end
   end
   
   /* acquire the type flag from EMTH so we know whether or not to add row to breakdown code */
   select @type_flag = TypeFlag
   from EMTH e, inserted i
   where e.EMCo = i.EMCo and e.RevTemplate = i.RevTemplate
   
   if @type_flag = 'O'
   begin
   if update(Rate)
     begin
     select @validcnt = count(*), @rate = min(i.Rate), @emco = min(i.EMCo), @emgroup = min(i.EMGroup),
            @revtemp = min(i.RevTemplate), @catgy = min(i.Category), @revcode = min(i.RevCode)
     from EMTD d, inserted i
     where d.EMCo = i.EMCo and d.EMGroup = i.EMGroup and d.RevTemplate = i.RevTemplate and d.Category = i.Category and
           d.RevCode = i.RevCode
     if @validcnt = 1
       begin
       /* update lone Bdown code in EMTD when a change is made in EMTC */
       update bEMTD
       set Rate = @rate
       where EMCo = @emco and EMGroup = @emgroup and RevTemplate = @revtemp and Category = @catgy and
             RevCode = @revcode
   
       if @@rowcount <> 1
         begin
         select @errmsg = 'Errors updating the revenue breakdown code'
         goto error
         end
       end
     end
   end
   
   
    /* Audit inserts */
    if not exists (select * from inserted i, EMCO e
    	where i.EMCo = e.EMCo and e.AuditRevenueRateCateg = 'Y')
    	return
   
    insert into bHQMA select 'bEMTC', 'EM Company: ' + convert(char(3), i.EMCo) + ' RevTemplate: ' + i.RevTemplate + ' Category: ' + i.Category +
       ' EMGroup: ' + convert(varchar(3),i.EMGroup) + ' RevCode: ' + i.RevCode,
       i.EMCo, 'C', 'AllowOrideFlag', d.AllowOrideFlag, i.AllowOrideFlag, getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and i.RevTemplate = d.RevTemplate and i.Category = d.Category and
       i.EMGroup = d.EMGroup and i.RevCode = d.RevCode and i.AllowOrideFlag <> d.AllowOrideFlag and
       e.EMCo = i.EMCo and e.AuditRevenueRateCateg = 'Y'
   
    insert into bHQMA select 'bEMTC', 'EM Company: ' + convert(char(3), i.EMCo) + ' RevTemplate: ' + i.RevTemplate + ' Category: ' + i.Category +
       ' EMGroup: ' + convert(varchar(3),i.EMGroup) + ' RevCode: ' + i.RevCode,
       i.EMCo, 'C', 'Rate', d.Rate, i.Rate, getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and i.RevTemplate = d.RevTemplate and i.Category = d.Category and
       i.EMGroup = d.EMGroup and i.RevCode = d.RevCode and i.Rate <> d.Rate and
       e.EMCo = i.EMCo and e.AuditRevenueRateCateg = 'Y'
   
    insert into bHQMA select 'bEMTC', 'EM Company: ' + convert(char(3), i.EMCo) + ' RevTemplate: ' + i.RevTemplate + ' Category: ' + i.Category +
       ' EMGroup: ' + convert(varchar(3),i.EMGroup) + ' RevCode: ' + i.RevCode,
       i.EMCo, 'C', 'DiscFromStdRate', d.Rate, i.Rate, getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and i.RevTemplate = d.RevTemplate and i.Category = d.Category and
       i.EMGroup = d.EMGroup and i.RevCode = d.RevCode and i.DiscFromStdRate <> d.DiscFromStdRate and
       e.EMCo = i.EMCo and e.AuditRevenueRateCateg = 'Y'
   
   
    return
   
    error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot update EMTC'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biEMTC] ON [dbo].[bEMTC] ([EMCo], [RevTemplate], [Category], [RevCode], [EMGroup]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMTC] ([KeyID]) ON [PRIMARY]
GO
