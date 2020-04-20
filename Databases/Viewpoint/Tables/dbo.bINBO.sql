CREATE TABLE [dbo].[bINBO]
(
[INCo] [dbo].[bCompany] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Loc] [dbo].[bLoc] NOT NULL,
[FinMatl] [dbo].[bMatl] NOT NULL,
[CompLoc] [dbo].[bLoc] NOT NULL,
[CompMatl] [dbo].[bMatl] NOT NULL,
[Units] [numeric] (14, 5) NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biINBO] ON [dbo].[bINBO] ([INCo], [MatlGroup], [Loc], [FinMatl], [CompLoc], [CompMatl]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bINBO] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
   CREATE  trigger [dbo].[btINBOd] on [dbo].[bINBO] for DELETE as
   

/*--------------------------------------------------------------
*  Created By:	GR	11/16/1999
*  Modified:	CHS	11/12/2009	- #135958
*
*  Delete trigger for IN Bill of Materials Override Detail
*
*--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- HQ Auditing
   insert bHQMA select 'bINBO',
					'INCo:' + convert(varchar(3),d.INCo) 
						+ ' Loc:' + d.Loc 
						+ ' MatlGroup:' + cast(d.MatlGroup as varchar(3)) 
						+ ' FinMatl:' + d.FinMatl 
						+ ' CompLoc:' + d.CompLoc 
						+ ' CompMatl:' + d.CompMatl,
   
       d.INCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   from deleted d
   join bINCO c on d.INCo = c.INCo
   join bINBL h on d.INCo = h.INCo and d.Loc = h.Loc and d.MatlGroup=h.MatlGroup and d.FinMatl=h.FinMatl
   where c.AuditBoM = 'Y'   -- check audit and purge flags
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot delete IN Bill of Material Override Detail'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 

   
   CREATE trigger [dbo].[btINBOi] on [dbo].[bINBO] for INSERT as   

/*--------------------------------------------------------------
* Created By:	GR	11/15/1999
* Modified By:	CHS	11/12/2009	- #135958
*
* Insert trigger for IN Bill of Material Override
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
   
   --validate Location
   select @validcnt=count(*) from bINLM a JOIN inserted i on i.INCo=a.INCo and i.Loc=a.Loc
   if @validcnt <> @numrows
       begin
       select @errmsg='Invalid Location '
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
   select @validcnt = count(*) from bINMT a JOIN inserted i on i.FinMatl = a.Material
   and i.MatlGroup=a.MatlGroup and i.INCo=a.INCo and i.Loc=a.Loc
   if @validcnt <> @numrows
       begin
    	select @errmsg = 'Invalid Material '
    	goto error
    	end
   
   --validate Component Location
   select @validcnt=count(*) from bINLM a JOIN inserted i on i.CompLoc=a.Loc and i.INCo=a.INCo
   if @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid Location '
       goto error
       end
   
   --validate Component Material
   select @validcnt = count(*) from bHQMT a JOIN inserted i on i.CompMatl = a.Material
   and i.MatlGroup=a.MatlGroup
   if @validcnt <> @numrows
       begin
    	select @errmsg = 'Invalid Material '
    	goto error
    	end
   
   --check whether Bill of Materials override Header exists
   select @validcnt=count(*) from bINBL a JOIN inserted i on i.INCo=a.INCo and i.Loc=a.Loc
   and i.MatlGroup=a.MatlGroup and i.FinMatl=a.FinMatl
   if @validcnt <> @numrows
       begin
       select @errmsg='Bill of Material Override header does not exists '
       goto error
       end
   
   --HQ Auditing
   INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   SELECT 'bINBO',
			'INCo:' + convert(varchar(3),i.INCo) 
				+ ' Loc:' + i.Loc 
				+ ' MatlGroup:' + cast(i.MatlGroup as varchar(3)) 
				+ ' FinMatl:' + i.FinMatl 
				+ ' CompLoc:' + i.CompLoc 
				+ ' CompMatl:' + i.CompMatl,
			i.INCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   FROM inserted i join bINCO c on c.INCo = i.INCo and c.AuditBoM = 'Y'
   
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot insert IN Bill of Material Override'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
   
   CREATE  trigger [dbo].[btINBOu] on [dbo].[bINBO] for UPDATE as

/*--------------------------------------------------------------
* Created By:	GR	11/03/1999
* Modified By:	CHS	11/12/2009	- #135958
*
*  Update trigger for IN Bill of Material Override
*
*--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- verify primary key not changed
   select @validcnt = count(*) from inserted i
   join deleted d on d.INCo = i.INCo and d.FinMatl = i.FinMatl and d.CompLoc=i.CompLoc
   and d.MatlGroup=i.MatlGroup and d.Loc=i.Loc and d.CompMatl=i.CompMatl
   if @validcnt <> @numrows
		begin
		select @errmsg = 'Cannot change IN Company/LocGroup/Finished or Component Material '
		goto error
		end
   
   -- HQ Auditing
   if exists(select * from inserted i join bINCO a on i.INCo = a.INCo and a.AuditBoM = 'Y')
		begin

		insert into bHQMA select 'bINBO',
			'INCo:' + convert(varchar(3),i.INCo) 
				+ ' Loc:' + i.Loc 
				+ ' MatlGroup:' + cast(i.MatlGroup as varchar(3))
				+ ' FinMatl:' + i.FinMatl 
				+ ' CompLoc:' + i.CompLoc 
				+ ' CompMatl:' + i.CompMatl,
			i.INCo, 'C', 'Units', d.Units, i.Units, getdate(), SUSER_SNAME()
		from inserted i    	
		join deleted d on d.INCo = i.INCo 
			and d.FinMatl = i.FinMatl 
			and d.CompLoc=i.CompLoc
			and d.MatlGroup=i.MatlGroup 
			and d.Loc=i.Loc 
			and d.CompMatl=i.CompMatl
		join bINCO a on a.INCo = i.INCo
		where d.Units <> i.Units and a.AuditBoM = 'Y'
    	
       end
   
   return
   
    error:
       select @errmsg = @errmsg + ' - cannot update IN Bill of Material Override'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
  
 



GO
