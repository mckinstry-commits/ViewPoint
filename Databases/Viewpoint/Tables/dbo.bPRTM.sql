CREATE TABLE [dbo].[bPRTM]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[Template] [smallint] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPRTM] ON [dbo].[bPRTM] ([PRCo], [Template]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRTM] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   CREATE    trigger [dbo].[btPRTMd] on [dbo].[bPRTM] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created by: GG 03/21/01
    *  Modified by:	EN 10/9/02 - issue 18877 change double quotes to single
    *					EN 02/20/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    *	Delete trigger on bPRTM Template Master - checks for existing Craft Template
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- check for Craft Template
   if exists(select * from dbo.bPRCT w with (nolock) join deleted d on w.PRCo = d.PRCo and w.Template = d.Template)
    	begin
   	select @errmsg = 'Craft Templates exist'
   	goto error
   	end
   
   /* Audit PR Template deletions */
   insert into dbo.bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRTM', ' Template:' + convert(varchar(4),d.Template),
       d.PRCo, 'D', null, null, null, getdate(), SUSER_SNAME()
   	from deleted d join dbo.PRCO p with (nolock) on d.PRCo = p.PRCo where p.AuditCraftClass = 'Y'
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete Template!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
