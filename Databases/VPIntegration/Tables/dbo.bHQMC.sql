CREATE TABLE [dbo].[bHQMC]
(
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Category] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[GLAcct] [dbo].[bGLAcct] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   /****** Object:  Trigger dbo.btHQMCd    Script Date: 8/28/99 9:37:34 AM ******/
   CREATE     trigger [dbo].[btHQMCd] on [dbo].[bHQMC] for DELETE as
   

/*----------------------------------------------------------
    *  Created:  ??
    *  Modified: 04/10/02 CMW - Replaced NULL for HQMA.Company with MaterialGroup (issue # 16840).
    *            07/12/02 CMW - Fixed multiple entry problem (issue # 17902).
    *            08/12/02 CMW - Fixed string/integer problem (issue # 18249).
    *
    *	This trigger rejects delete in bHQMC (HQ Matl Categories)
    *	if a dependent record is found in:
    *
    *		HQMT Materials
    *
    *	Audit deletions if any HQ Company using the Mat'l Group has the
    *	AuditMatl option set.
    */---------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* check HQ Materials */
   if exists(select * from bHQMT s, deleted d where s.MatlGroup = d.MatlGroup and
   	s.Category = d.Category)
   	begin
   	select @errmsg = 'HQ Materials in this Category exist'
   	goto error
   	end
   
   /* Audit HQ Category deletions */
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHQMC', 'Matl. Group/Category: ' + convert(varchar(3),d.MatlGroup) + '  ' + min(d.Category), d.MatlGroup,
   		'D', null, null, null, getdate(), SUSER_SNAME()
   		from deleted d, bHQCO c
   		where d.MatlGroup = c.MatlGroup and c.AuditMatl = 'Y'
       group by d.MatlGroup
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete HQ Material Category!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   /****** Object:  Trigger dbo.btHQMCi    Script Date: 8/28/99 9:37:34 AM ******/
   CREATE     trigger [dbo].[btHQMCi] on [dbo].[bHQMC] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created:  ??
    *  Modified: 04/10/02 CMW - Replaced NULL for HQMA.Company with MaterialGroup (issue # 16840).
    *            07/12/02 CMW - Fixed multiple entry problem (issue # 17902).
    *            08/12/02 CMW - Fixed string/numeric problem (issue # 18249).
    *
    *	This trigger rejects insertion in bHQMC (Material Categories)
    *	if any of the following error conditions exist:
    *
    *		Invalid MatlGroup vs bHQGP.Grp
    *
    *	Audit inserts if any HQ Company using the Mat'l Group has the AuditMatl
    *	option set.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* validate Material Group */
   select @validcnt = count(*) from inserted i, bHQGP g where i.MatlGroup = g.Grp
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Material Group'
   	goto error
   	end
   
   /* add HQ Master Audit entry */
   insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHQMC',  'Matl. Group/Category: ' + convert(varchar(3), i.MatlGroup) + '  ' + min(i.Category),
   	i.MatlGroup, 'A', null, null, null, getdate(), SUSER_SNAME() from inserted i, bHQCO h
   		where i.MatlGroup = h.MatlGroup and AuditMatl = 'Y'
       group by i.MatlGroup
   
   /* add HQ Master Audit entry - see note in header re selection of @audit */
   if not exists(select * from inserted i, bHQCO h where i.MatlGroup = h.MatlGroup
   		and h.AuditMatl = 'Y') return
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot insert Material Category!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   /****** Object:  Trigger dbo.btHQMCu    Script Date: 8/28/99 9:37:34 AM ******/
   CREATE      trigger [dbo].[btHQMCu] on [dbo].[bHQMC] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created:  ??
    *  Modified: 04/10/02 CMW - Replaced NULL for HQMA.Company with MaterialGroup (issue # 16840).
    *            07/12/02 CMW - Fixed multiple entry problem (issue # 17902).
    *            08/12/02 CMW - Fixed string/integer problem (issue # 18249).
    *
    *	This trigger rejects update in bHQMC (HQ Material Categories)
    *	if any of the following error conditions exist:
    *
    *		Cannot change MatlGroup
    *		Cannot change Category
    *
    *	Audit inserts if any HQ Company using the Mat'l Group has the AuditMatl
    *	option set.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* reject key changes */
   select @validcnt = count(*) from deleted d, inserted i
   	where d.MatlGroup = i.MatlGroup and d.Category = i.Category
   if @numrows <> @validcnt
   	begin
   	select @errmsg = 'Cannot change Material Group or Category'
   	goto error
   	end
   
   /* update HQ Master Audit if any company using this Material Group has auditing turned on */
   if not exists(select * from inserted i, bHQCO c where i.MatlGroup = c.MatlGroup
   		and c.AuditMatl = 'Y') return
   
   insert into bHQMA select 'bHQMC', 'Matl. Group/Category: ' + convert(varchar(3),i.MatlGroup) + '  ' + min(i.Category),
   	i.MatlGroup, 'C', 'Description', min(d.Description), min(i.Description), getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bHQCO c
   	where i.MatlGroup = d.MatlGroup and i.Category = d.Category and i.Description <> d.Description
   		and i.MatlGroup = c.MatlGroup and c.AuditMatl = 'Y'
       group by i.MatlGroup
   
   insert into bHQMA select 'bHQMC', 'Matl. Group/Category: ' + convert(varchar(3),i.MatlGroup) + '  ' + min(i.Category),
   	i.MatlGroup, 'C', 'GL Account', min(d.GLAcct), min(i.GLAcct), getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bHQCO c
   	where i.MatlGroup = d.MatlGroup and i.Category = d.Category and i.GLAcct <> d.GLAcct
   		and i.MatlGroup = c.MatlGroup and c.AuditMatl = 'Y'
       group by i.MatlGroup
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot update Material Category!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHQMC] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biHQMC] ON [dbo].[bHQMC] ([MatlGroup], [Category]) ON [PRIMARY]
GO
