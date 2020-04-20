CREATE TABLE [dbo].[bINBH]
(
[INCo] [dbo].[bCompany] NOT NULL,
[LocGroup] [dbo].[bGroup] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[FinMatl] [dbo].[bMatl] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
   CREATE trigger [dbo].[btINBHd] on [dbo].[bINBH] for DELETE as
/*--------------------------------------------------------------
*  Created By:	GR	11/16/1999
*  Modified:	GG	03/04/2000
*				CHS	10/27/2009	- issue #135955
*
*  Delete trigger for IN Bill of Materials Header
*
*--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
	if exists(select * from deleted d join bINBM m on d.INCo = m.INCo and d.LocGroup = m.LocGroup and d.MatlGroup = m.MatlGroup and d.FinMatl = m.FinMatl)
		begin
		select @errmsg = 'Bill of Materials has components'
		goto error
		end
   	
   	-- #135955
	-- HQ Auditing
	insert bHQMA select 'bINBH','INCo:' + convert(varchar(3),d.INCo) + '  LocGroup: ' + convert(varchar(3), d.LocGroup) + '  MatlGroup: ' + cast(d.MatlGroup as varchar(3)) + '  FinMatl: ' + d.FinMatl,
		d.INCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
	from deleted d
	join bINCO c on d.INCo = c.INCo
	where c.AuditBoM = 'Y'   -- check audit and purge flags
   	
   	
   return

   error:
      select @errmsg = @errmsg + ' - cannot delete IN Bill of Materials Header'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[btINBHi] on [dbo].[bINBH] for INSERT as
/*--------------------------------------------------------------
 *  Created By:		CHS	10/28/2009	-	#135955
 *	Modified By:	
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
    	
    		-- HQ Auditing
	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bINBH','INCo:' + cast(i.INCo as varchar(3)) + '  LocGroup: ' + cast(i.LocGroup as varchar(3)) + '  MatlGroup: ' + cast(i.MatlGroup as varchar(3))
	 + '  FinMatl: ' + i.FinMatl, 
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

CREATE TRIGGER [dbo].[btINBHu] on [dbo].[bINBH] for UPDATE as  
/*--------------------------------------------------------------
*	Created By:		CHS	10/28/2009	-	#135955
*	Modified By:	
*
* Insert trigger for IN Bill of Material
* Adds to master audit table
*--------------------------------------------------------------*/
	declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int

	select @numrows = @@rowcount
	if @numrows = 0 return

	set nocount on

	-- verify primary key not changed
	select @validcnt = count(*) from inserted i
	join deleted d on d.INCo = i.INCo and d.FinMatl = i.FinMatl
	and d.MatlGroup=i.MatlGroup and d.LocGroup=i.LocGroup
	if @validcnt <> @numrows
		begin
		select @errmsg = 'Cannot change IN Company/LocGroup or Finished Material '
		goto error
		end
		
	return

	error:
		select @errmsg = @errmsg + ' - cannot update IN Bill of Material'
		RAISERROR(@errmsg, 11, -1);
		rollback transaction
GO
CREATE UNIQUE CLUSTERED INDEX [biINBH] ON [dbo].[bINBH] ([INCo], [LocGroup], [MatlGroup], [FinMatl]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bINBH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
