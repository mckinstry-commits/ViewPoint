CREATE TABLE [dbo].[bINBL]
(
[INCo] [dbo].[bCompany] NOT NULL,
[Loc] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[FinMatl] [dbo].[bMatl] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biINBL] ON [dbo].[bINBL] ([INCo], [Loc], [MatlGroup], [FinMatl]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bINBL] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btINBLd] on [dbo].[bINBL] for DELETE as
   

/*--------------------------------------------------------------
*  Created By:	GR	11/16/1999
*  Modified:	GG	03/04/2000
*				CHS	11/12/2009	- #135958
*
*  Delete trigger for IN Bill of Materials Override Header
*
*--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- check for Bill of Matl Override components
   if exists(select * from deleted d join bINBO c on d.INCo = c.INCo and d.Loc = c.Loc
   and d.MatlGroup = c.MatlGroup and d.FinMatl = c.FinMatl)
   	begin
   	select @errmsg = 'Bill of Material has Components'
   	goto error
   	end
   	
   	
   --HQ Auditing
   INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   SELECT 'bINBL',
			'INCo:' + convert(varchar(3),d.INCo) 
				+ ' Loc:' + d.Loc 
				+ ' MatlGroup:' + cast(d.MatlGroup as varchar(3))
				+ ' FinMatl:' + d.FinMatl,
			d.INCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   FROM deleted d 
   join bINCO c on c.INCo = d.INCo and c.AuditBoM = 'Y' 
   	
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete IN Bill of Materials Override Header'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
   CREATE trigger [dbo].[btINBLi] on [dbo].[bINBL] for INSERT as   

/*--------------------------------------------------------------
* Created By:	CHS	11/12/2009	- #135958
*
* Insert trigger for IN Bill of Material Override
* Adds to master audit table
*--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
      
   set nocount on


     --HQ Auditing
   INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   SELECT 'bINBL',
			'INCo:' + convert(varchar(3),i.INCo) 
				+ ' Loc:' + i.Loc 
				+ ' MatlGroup:' + cast(i.MatlGroup as varchar(3))
				+ ' FinMatl:' + i.FinMatl,
			i.INCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   FROM inserted i join bINCO c on c.INCo = i.INCo and c.AuditBoM = 'Y' 
   
   
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete IN Bill of Materials Override Header'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
   CREATE trigger [dbo].[btINBLu] on [dbo].[bINBL] for UPDATE as

/*--------------------------------------------------------------
* Created By:	CHS	11/12/2009	- #135958
*
* Insert trigger for IN Bill of Material Override
* Adds to master audit table
*--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
      
   set nocount on


   -- HQ Auditing
   if exists(select * from inserted i join bINCO a on i.INCo = a.INCo and a.AuditBoM = 'Y')
		begin

		insert into bHQMA select 'bINBL',
			'INCo:' + convert(varchar(3),i.INCo) 
				+ ' Loc:' + i.Loc 
				+ ' MatlGroup:' + cast(i.MatlGroup as varchar(3))
				+ ' FinMatl:' + i.FinMatl,
			i.INCo, 'C', null, null, null, getdate(), SUSER_SNAME()
		from inserted i    	
		join deleted d on d.INCo = i.INCo 
			and d.FinMatl = i.FinMatl 
			and d.MatlGroup=i.MatlGroup 
			and d.Loc=i.Loc 
		join bINCO a on a.INCo = i.INCo
		where a.AuditBoM = 'Y'
    	
       end
   
   
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete IN Bill of Materials Override Header'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
