CREATE TABLE [dbo].[bPRLD]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[LocalCode] [dbo].[bLocalCode] NOT NULL,
[DLCode] [dbo].[bEDLCode] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPRLD] ON [dbo].[bPRLD] ([PRCo], [LocalCode], [DLCode]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRLD] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btPRSDd    Script Date: 7/18/2003 3:40:50 PM ******/
   CREATE   trigger [dbo].[btPRLDd] on [dbo].[bPRLD] for DELETE as
   

/*--------------------------------------------------------------
    * Created: DC 07/18/03 -- #21663  Add HQMA audit to these tables.
    * Modified:   EN 02/18/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    * Delete trigger on PR Local Deduction Information
    * Adds audit records info to HQMA
    *
    *--------------------------------------------------------------*/
   declare @errmsg varchar(255)
   
   
   set nocount on
   -- add HQ Master Audit entry   DC #21663
    if exists (select top 1 1 from deleted d join dbo.bPRCO a with (nolock) on a.PRCo = d.PRCo where a.AuditTaxes = 'Y')
     	begin
   	INSERT INTO dbo.bHQMA
   	     (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bPRLD', 'PRCo: ' + convert(char(2), d.PRCo) + ' LocalCode: ' + d.LocalCode + ' DLCode: ' + convert(char(3),d.DLCode),
              d.PRCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
           FROM deleted d
   	END
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR Local Deduction Information (bPRLD)'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btPRLDi    Script Date: 7/18/2003 3:17:23 PM ******/
   CREATE      trigger [dbo].[btPRLDi] on [dbo].[bPRLD] for INSERT as
   

/*-----------------------------------------------------------------
    * Created by: MV 1/28/02
    * Modified:    DC 7/18/03 #21663 - Add HQMA audit to these tables.
    *				EN 02/18/03 - issue 23061  added isnull check, with (nolock), and dbo
    *											and corrected old syle joins
    *
    * Insert trigger on PR Local
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   /* validate PR Company */
   select @validcnt = count(1) from dbo.bHQCO c with (nolock) join inserted i on c.HQCo = i.PRCo
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Company# '
   	goto error
   	end
   
   /* validate DLCode */
   select @validcnt = count(1) from inserted i join dbo.PRDL c with (nolock) on i.PRCo = c.PRCo and i.DLCode = c.DLCode
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Dedn/Liab Code '
   	goto error
   	end
   
   /*validate CalCategory.*/
   select @validcnt = count(1) from dbo.bPRDL c with (nolock) join inserted i on c.PRCo = i.PRCo and i.DLCode = c.DLCode
       where c.CalcCategory not in ('L', 'A') 
   if @validcnt <> 0
   	begin
   	select @errmsg = 'Calculation category must be L or A. '
   	goto error
   	end
   
   -- add HQ Master Audit entry   DC #21663
    if exists (select top 1 1 from inserted i join dbo.bPRCO a with (nolock) on a.PRCo = i.PRCo where a.AuditTaxes = 'Y')
     	begin
   	Insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 select 'bPRLD',  'PRCo: ' + convert(char(2), i.PRCo) + ' LocalCode: ' + i.LocalCode + ' DLCode: ' + convert(char(3),i.DLCode), i.PRCo, 'A',
   	 null, null, null, getdate(), SUSER_SNAME() from inserted i join dbo.bPRLD a on i.PRCo=a.PRCo and i.LocalCode=a.LocalCode and i.DLCode=a.DLCode
   	END
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Local item!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   CREATE   trigger [dbo].[btPRLDu] on [dbo].[bPRLD] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created: MV 1/28/02
    *	Modified: GG 07/18/02 - cleanup
    *				EN 02/18/03 - issue 23061  added isnull check
    *                
    * Update tirgger for PR Local Detail
    *
    * Reject primary keys value changes
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   if update(PRCo)
   	begin
   	select @errmsg = 'PR Company cannot be updated, it is a key value '
   	goto error
   	end
   if update(LocalCode)
   	begin
   	select @errmsg = 'Local Code cannot be updated, it is a key value '
   	goto error
   	end
   if update(DLCode)
   	begin
   	select @errmsg = 'DLCode cannot be updated, it is a key value '
   	goto error
   	end
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Local Detail!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
   
  
 



GO
