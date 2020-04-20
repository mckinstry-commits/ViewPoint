CREATE TABLE [dbo].[bPRES]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[EarnCode] [dbo].[bEDLCode] NOT NULL,
[SubjEarnCode] [dbo].[bEDLCode] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  TRIGGER [dbo].[btPRESd] ON [dbo].[bPRES] 
   FOR DELETE 
   AS
   
 /*-----------------------------------------------------------------
	*	Created: EN  #129888
    * 	Modified: 
    *
    *	This trigger validates deletion in bPRES (PR Subject Earnings Codes)
    */----------------------------------------------------------------
   
   declare @errmsg varchar(255)

   /* add HQ Master Audit entry */
   insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 select 'bPRES',  'PR Co#: ' + convert(varchar(10), d.PRCo) + ' EarnCode: ' + convert(varchar(10), d.EarnCode) + 
	 ' SubjEarnCode: ' + convert(varchar(10), d.SubjEarnCode), d.PRCo, 'D',
   	 null, null, null, getdate(), SUSER_SNAME() from deleted d join dbo.PRCO a with (nolock) on d.PRCo=a.PRCo
        where a.AuditDLs='Y'
   
     return
     error:
     	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR Subject Earnings Codes!'
         	RAISERROR(@errmsg, 11, -1);
         	rollback transaction

   



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  TRIGGER [dbo].[btPRESi] ON [dbo].[bPRES] 
   FOR INSERT
   as
   
 /*-----------------------------------------------------------------
	*	Created: EN  #129888
    * 	Modified: 
    *
    *	This trigger validates insertion in bPRES (PREC Subject Earnings)
    */----------------------------------------------------------------
  
   declare @errmsg varchar(255)

   /* add HQ Master Audit entry */
   insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 select 'bPRES',  'PR Co#: ' + convert(varchar(10), i.PRCo) + ' EarnCode: ' + convert(varchar(10), i.EarnCode) + 
	 ' SubjEarnCode: ' + convert(varchar(10), i.SubjEarnCode), i.PRCo, 'A',
   	 null, null, null, getdate(), SUSER_SNAME() from inserted i join dbo.PRCO a with (nolock) on i.PRCo=a.PRCo
        where a.AuditDLs='Y'


      return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Subject Earnings!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction

   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  TRIGGER [dbo].[btPRESu] ON [dbo].[bPRES] 
   FOR UPDATE 
   AS
   
   

declare @rcode int,@errmsg varchar(255)
   
   if update(SubjEarnCode)
   begin
   	select @rcode = 1,@errmsg = 'Cannot update Subject Earn Code.'
   	raiserror(@errmsg,9,-1)
   	return
   end
    /* validate PR Company */
    if update(PRCo)
    	begin
    	select @errmsg = 'PR Company cannot be updated, it is a key value '
    	goto error
    	end
    if update(EarnCode)
    	begin
    	select @errmsg = 'EarnCode cannot be updated, it is a key value '
    	goto error
    	end
    if update(SubjEarnCode)
    	begin
    	select @errmsg = 'Subject EarnCode cannot be updated, it is a key value '
    	goto error
    	end


     return
     error:
		select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Subject Earnings Code!'
     	RAISERROR(@errmsg, 11, -1);
     	rollback transaction
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRES] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRES] ON [dbo].[bPRES] ([PRCo], [EarnCode], [SubjEarnCode]) ON [PRIMARY]
GO
