CREATE TABLE [dbo].[bPRFD]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[DLCode] [dbo].[bEDLCode] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPRFD] ON [dbo].[bPRFD] ([PRCo], [DLCode]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRFD] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btPRLDd    Script Date: 7/21/2003 1:02:44 PM ******/
   CREATE    trigger [dbo].[btPRFDd] on [dbo].[bPRFD] for DELETE as
   

/*--------------------------------------------------------------
    * Created: DC 07/18/03 -- #21663  Add HQMA audit to these tables.
    * Modified:	EN 02/18/03 - issue 23061  added isnull check, with (nolock), and dbo   
    *
    * Delete trigger on PR Federal Deduction Information
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
   	SELECT 'bPRFD', 'PRCo: ' + convert(char(2), d.PRCo) + ' DLCode: ' + convert(char(3),d.DLCode),
              d.PRCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
           FROM deleted d
   	END
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR Federal Deduction Information (bPRFD)'
      RAISERROR(@errmsg, 11, -1);
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btPRFDi    Script Date: 7/21/2003 11:22:14 AM ******/
   CREATE      trigger [dbo].[btPRFDi] on [dbo].[bPRFD] for INSERT as
   

/*-----------------------------------------------------------------
    * Created by: MV 1/28/02
    * Modified:   DC 7/21/03  #21663  -- add HQ Master Audit entry
    *				EN 02/18/03 - issue 23061  added isnull check, with (nolock), and dbo
    *											and corrected old syle joins
    *
    * Insert trigger on PR Fed
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
       where c.CalcCategory not in ('F', 'A') 
   if @validcnt <> 0
   	begin
   	select @errmsg = 'DLCode calculation category must be F or A. '
   	goto error
   	end
   
   -- add HQ Master Audit entry   DC #21663
    if exists (select top 1 1 from inserted i join dbo.bPRCO a with (nolock) on a.PRCo = i.PRCo where a.AuditTaxes = 'Y')
     	begin
   	Insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 select 'bPRFD',  'PRCo: ' + convert(char(2), i.PRCo)+ ' DLCode: '+ convert(char(3), i.DLCode), i.PRCo, 'A',
   	 null, null, null, getdate(), SUSER_SNAME() from inserted i join dbo.bPRFD a on i.PRCo=a.PRCo and i.DLCode=a.DLCode
   	END
   
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Fed item!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   CREATE  trigger [dbo].[btPRFDu] on [dbo].[bPRFD] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created: MV 1/28/02
    *	Modified:	EN 02/18/03 - issue 23061  added isnull check, with (nolock), and dbo
    *								 and corrected old syle joins
    *                
    * Validate PRCo and DLCode and CalcCategory.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   
   if update(PRCo)
       begin
       select @validcnt = count(*) from dbo.bHQCO c with (nolock) join inserted i on c.HQCo = i.PRCo
   	if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Company# '
   	goto error
   	end
       end
   
   if update(DLCode)
       begin
       select @validcnt = count(*) from inserted i join dbo.PRDL c with (nolock) on i.PRCo = c.PRCo and i.DLCode = c.DLCode
   	if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Dedn/Liab Code '
   	goto error
   	end
       end
   
   /*validate CalCategory.*/
   select @validcnt = count(*) from dbo.bPRDL c with (nolock) join inserted i on c.PRCo = i.PRCo and i.DLCode = c.DLCode
       where c.CalcCategory not in ('F', 'A') 
   	if @validcnt <> 0
   	begin
   	select @errmsg = 'DLCode calculation category must be F or A. '
   	goto error
   	end
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Fed Items!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
  
 



GO
