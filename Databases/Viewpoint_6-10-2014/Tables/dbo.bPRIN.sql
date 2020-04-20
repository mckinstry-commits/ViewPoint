CREATE TABLE [dbo].[bPRIN]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NOT NULL,
[InsCode] [dbo].[bInsCode] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[ApplyLimit] [dbo].[bYN] NOT NULL,
[EarnLimit] [dbo].[bDollar] NULL,
[UseThreshold] [dbo].[bYN] NOT NULL,
[ThresholdRate] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bPRIN_ThresholdRate] DEFAULT ((0)),
[OverrideInsCode] [dbo].[bInsCode] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   
   CREATE      trigger [dbo].[btPRINd] on [dbo].[bPRIN] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created: ES 03/05/04
    * 	Modified: mh 10/1/04 - reject delete if detail exists in PRID
    *
    *	This trigger Adds HQ Master Audit entry.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   if exists(select 1 from deleted d join bPRID p on d.PRCo = p.PRCo and d.State = p.State and d.InsCode = p.InsCode)
   	begin
   		select @errmsg = 'Deduction/Liability Code Detail exists in bPRID.'
   		goto error	
   	end
   
   /* add HQ Master Audit entry */
   insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 select 'bPRIN', 'PR Co#: ' + convert(char(3),d.PRCo) + 
   	 ' PR State: ' + convert(char(2), d.State) + ' Code: ' + convert(char(10), d.InsCode), 
   	 d.PRCo, 'D', null, null, null, getdate(), SUSER_SNAME() from deleted d
        join dbo.PRCO a with (nolock) on d.PRCo=a.PRCo where a.AuditStateIns='Y'
   
   
   return
   
   error:
    	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR State Insurance Codes!'
        	RAISERROR(@errmsg, 11, -1);
        	rollback transaction
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE  trigger [dbo].[btPRINi] on [dbo].[bPRIN] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created: ES 03/05/04
    * 	Modified: 
    *
    *	This trigger Adds HQ Master Audit entry.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* add HQ Master Audit entry */
   insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 select 'bPRIN', 'PR Co#: ' + convert(char(3),i.PRCo) + 
   	 ' PR State: ' + convert(char(2), State) + 'Code: ' + convert(char(10), InsCode), 
   	 i.PRCo, 'A', null, null, null, getdate(), SUSER_SNAME() from inserted i
        join dbo.PRCO a with (nolock) on i.PRCo=a.PRCo where a.AuditStateIns='Y'
   
   
   return
   
   /*
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR State Insurance Code!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   */
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
/****** Object:  Trigger [dbo].[btPRINu]    Script Date: 12/27/2007 09:55:57 ******/
   CREATE   trigger [dbo].[btPRINu] on [dbo].[bPRIN] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created: ES 03/05/04 - issue 23814 added audit code
    *	Modified:	EN 12/27/08 - #126315  allow for 20 character EarnLimit when logging to HQMA
    *		  
    *                
    *  Issue 23814 added audit code
    */----------------------------------------------------------------
   declare @numrows int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   
   /* Audit updates */
   if exists (select 1 from inserted i join dbo.bPRCO a with (nolock) on a.PRCo = i.PRCo where a.AuditStateIns = 'Y')
   	begin
   	insert into dbo.bHQMA select 'bPRIN', 'PR Co#: ' + convert(char(3),i.PRCo) +
   	 ' PR State: ' + convert(char(2), i.State) + ' Code: ' + convert(char(10), i.InsCode),
   	 i.PRCo, 'C', 'Description', Convert(varchar(30),d.Description), Convert(varchar(30),i.Description),
   	 	getdate(), SUSER_SNAME()
    	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State and i.InsCode = d.InsCode
           where isnull(d.Description, '') <> isnull(i.Description, '')
   
   	insert into dbo.bHQMA select 'bPRIN', 'PR Co#: ' + convert(char(3),i.PRCo) +
   	 ' PR State: ' + convert(char(2), i.State) + ' Code: ' + convert(char(10), i.InsCode),
   	 i.PRCo, 'C', 'ApplyLimit', Convert(char(1),d.ApplyLimit), Convert(char(1),i.ApplyLimit),
   	 	getdate(), SUSER_SNAME()
    	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State and i.InsCode = d.InsCode
           where d.ApplyLimit <> i.ApplyLimit
   
   	insert into dbo.bHQMA select 'bPRIN', 'PR Co#: ' + convert(char(3),i.PRCo) +
   	 ' PR State: ' + convert(char(2), i.State) + ' Code: ' + convert(char(10), i.InsCode),
   	 i.PRCo, 'C', 'EarnLimit', Convert(varchar(20),d.EarnLimit), Convert(varchar(20),i.EarnLimit),
   	 	getdate(), SUSER_SNAME()
    	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State and i.InsCode = d.InsCode
           where isnull(d.EarnLimit, 0) <> isnull(i.EarnLimit, 0)
   
   	insert into dbo.bHQMA select 'bPRIN', 'PR Co#: ' + convert(char(3),i.PRCo) +
   	 ' PR State: ' + convert(char(2), i.State) + ' Code: ' + convert(char(10), i.InsCode),
   	 i.PRCo, 'C', 'UseThreshold', Convert(char(1),d.UseThreshold), Convert(char(1),i.UseThreshold),
   	 	getdate(), SUSER_SNAME()
    	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State and i.InsCode = d.InsCode
           where d.UseThreshold <> i.UseThreshold
   
   	insert into dbo.bHQMA select 'bPRIN', 'PR Co#: ' + convert(char(3),i.PRCo) +
   	 ' PR State: ' + convert(char(2), i.State) + ' Code: ' + convert(char(10), i.InsCode),
   	 i.PRCo, 'C', 'ThresholdRate', Convert(varchar(21),d.ThresholdRate), Convert(varchar(21),i.ThresholdRate),
   	 	getdate(), SUSER_SNAME()
    	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State and i.InsCode = d.InsCode
           where isnull(d.ThresholdRate, 0) <> isnull(i.ThresholdRate, 0)
   
   	insert into dbo.bHQMA select 'bPRIN', 'PR Co#: ' + convert(char(3),i.PRCo) +
   	 ' PR State: ' + convert(char(2), i.State) + ' Code: ' + convert(char(10), i.InsCode),
   	 i.PRCo, 'C', 'OverrideInsCode', Convert(varchar(10),d.OverrideInsCode), Convert(varchar(10),i.OverrideInsCode),
   	 	getdate(), SUSER_SNAME()
    	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State and i.InsCode = d.InsCode
           where isnull(d.OverrideInsCode, '') <> isnull(i.OverrideInsCode, '')
   
   	end
   
   return
   
   
   
  
 



GO
ALTER TABLE [dbo].[bPRIN] WITH NOCHECK ADD CONSTRAINT [CK_bPRIN_ApplyLimit] CHECK (([ApplyLimit]='Y' OR [ApplyLimit]='N'))
GO
ALTER TABLE [dbo].[bPRIN] WITH NOCHECK ADD CONSTRAINT [CK_bPRIN_UseThreshold] CHECK (([UseThreshold]='Y' OR [UseThreshold]='N'))
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRIN] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
