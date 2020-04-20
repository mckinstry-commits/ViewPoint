CREATE TABLE [dbo].[bINBM]
(
[INCo] [dbo].[bCompany] NOT NULL,
[LocGroup] [dbo].[bGroup] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[FinMatl] [dbo].[bMatl] NOT NULL,
[CompMatl] [dbo].[bMatl] NOT NULL,
[Units] [numeric] (14, 5) NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE  trigger [dbo].[btINBMd] on [dbo].[bINBM] for DELETE as
   

/*--------------------------------------------------------------
*  Created By: GR 11/16/99
*  Modified:
*
*  Delete trigger for IN Bill of Materials Detail
*
*--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- HQ Auditing
   insert bHQMA select 'bINBM','INCo: ' + convert(varchar(3),d.INCo) + '  LocGroup: ' + convert(varchar(3), d.LocGroup) + '  MatlGroup: ' + cast(d.MatlGroup as varchar(3))
	 + '  FinMatl: ' + d.FinMatl + '  CompMatl: ' + d.CompMatl + '  Units: ' + cast(d.Units as varchar(12)),
       d.INCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   from deleted d
   join bINCO c on d.INCo = c.INCo
   join bINBH h on d.INCo = h.INCo and d.LocGroup = h.LocGroup and d.MatlGroup=h.MatlGroup and d.FinMatl=h.FinMatl
   where c.AuditBoM = 'Y'   -- check audit and purge flags
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot delete IN Bill of Material Detail'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
CREATE trigger [dbo].[btINBMi] on [dbo].[bINBM] for INSERT as
/*--------------------------------------------------------------
 *  Created By:		GR	11/15/99
 *	Modified By:	CHS	10/28/2009	-	#135955
 *
 * Insert trigger for IN Bill of Material
 * Adds to master audit table
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- validate IN Company
   select @validcnt = count(*) from bINCO c JOIN inserted i on i.INCo = c.INCo
   if @validcnt<>@numrows
       begin
    	select @errmsg = 'Invalid IN Company '
    	goto error
    	end
   
   --validate Location Group
   select @validcnt=count(*) from bINLG a JOIN inserted i on i.INCo=a.INCo and i.LocGroup=a.LocGroup
   if @validcnt <> @numrows
       begin
       select @errmsg='Invalid Location Group '
       goto error
       end
   
   --validate Material group
   select @validcnt = count(*) from bHQCO c
   JOIN inserted i on i.INCo = c.HQCo and i.MatlGroup = c.MatlGroup
   if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid Material Group for this Company '
    	goto error
    	end
   
   --validate Finished Material
   select @validcnt = count(*) from bHQMT a JOIN inserted i on i.FinMatl = a.Material and i.MatlGroup=a.MatlGroup
   if @validcnt <> @numrows
       begin
    	select @errmsg = 'Invalid Material '
    	goto error
    	end
   
   --validate Component Material
   select @validcnt = count(*) from bHQMT a JOIN inserted i on i.CompMatl = a.Material and i.MatlGroup=a.MatlGroup
   if @validcnt <> @numrows
       begin
    	select @errmsg = 'Invalid Material '
    	goto error
    	end
   
   --check whether Bill of Material Header record exists
   select @validcnt=count(*) from bINBH a JOIN inserted i on
   i.INCo=a.INCo and i.LocGroup=a.LocGroup and i.MatlGroup=a.MatlGroup
   and i.FinMatl=a.FinMatl
   if @validcnt <> @numrows
       begin
       select @errmsg= 'Bill of Material Header does not exists '
       goto error
       end
   
   
   
	-- --#135955  
	-- --HQ Auditing
	--INSERT INTO bHQMA
	--    (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)       
	--SELECT 'bINBM',' Material: ' + i.CompMatl, i.INCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
	--FROM inserted i join bINCO c on c.INCo = i.INCo and c.AuditBoM = 'Y'
	
	-- --#135955 
	-- HQ Auditing
	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bINBM','INCo: ' + cast(i.INCo as varchar(3)) + '  LocGroup: ' + cast(i.LocGroup as varchar(3)) + '  MatlGroup: ' + cast(i.MatlGroup as varchar(3))
	 + '  FinMatl: ' + i.FinMatl + '  CompMatl: ' + i.CompMatl + '  Units: ' + cast(i.Units as varchar(12)), 
	i.INCo, 'A', NULL, NULL, NULL, GETDATE(), SUSER_SNAME()
	FROM inserted i
	join dbo.bINCO c with (nolock) on c.INCo = i.INCo
	where c.AuditBoM = 'Y'     
   
  
   
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot insert IN Bill of Material'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  trigger [dbo].[btINBMu] on [dbo].[bINBM] for UPDATE as
   

/*--------------------------------------------------------------
* Created By:	GR	11/03/99
* Modified By:	CHS	10/28/2009	-	#135955
*
*  Update trigger for IN Bill of Material
*
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- verify primary key not changed
   select @validcnt = count(*) from inserted i
   join deleted d on d.INCo = i.INCo and d.FinMatl = i.FinMatl
   and d.MatlGroup=i.MatlGroup and d.LocGroup=i.LocGroup and d.CompMatl=i.CompMatl
   if @validcnt <> @numrows
       begin
    	select @errmsg = 'Cannot change IN Company/LocGroup/Finished or Component Material '
    	goto error
    	end
   
   --#135955
   ---- HQ Auditing
   --if exists(select * from inserted i join bINCO a on i.INCo = a.INCo and a.AuditBoM = 'Y')
   --    begin
   --    insert into bHQMA select 'bINBM', ' Material: ' + i.CompMatl, i.INCo, 'C',
   --        'Units', d.Units, i.Units, getdate(), SUSER_SNAME()
   -- 	from inserted i
   --    join deleted d on d.INCo = i.INCo and d.FinMatl = i.FinMatl
   --    and d.MatlGroup=i.MatlGroup and d.LocGroup=i.LocGroup and d.CompMatl=i.CompMatl
   --    join bINCO a on a.INCo = i.INCo
   -- 	where d.Units <> i.Units and a.AuditBoM = 'Y'
   --    end
   
    --#135955
    ---- HQ Auditing  
	if update(Units)
		begin
		insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 'bINBM', 'INCo: ' + cast(i.INCo as varchar(3)) + '  LocGroup: ' + cast(i.LocGroup as varchar(3)) 
			+ ' MatlGroup: ' + cast(i.MatlGroup as varchar(3)) + ' FinMatl: ' + i.FinMatl + ' CompMatl: ' 
			+ i.CompMatl + ' Units: ' + cast(i.Units as varchar(12)),
			i.INCo, 'C', 'Units', d.Units, i.Units, GETDATE(), SUSER_SNAME()
		from inserted i
		join deleted d on d.INCo = i.INCo and d.LocGroup=i.LocGroup and d.MatlGroup=i.MatlGroup and d.FinMatl=i.FinMatl and d.CompMatl=i.CompMatl
		join dbo.bINCO a (nolock) on a.INCo = i.INCo
		where a.AuditBoM = 'Y'
		end   
   
   
   
   return
   
    error:
       select @errmsg = @errmsg + ' - cannot update IN Bill of Material'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biINBM] ON [dbo].[bINBM] ([INCo], [LocGroup], [MatlGroup], [FinMatl], [CompMatl]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bINBM] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
