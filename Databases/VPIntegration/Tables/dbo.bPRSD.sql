CREATE TABLE [dbo].[bPRSD]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NOT NULL,
[DLCode] [dbo].[bEDLCode] NOT NULL,
[BasedOn] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btPRSId    Script Date: 7/18/2003 1:07:28 PM ******/
   CREATE   trigger [dbo].[btPRSDd] on [dbo].[bPRSD] for DELETE as
   

/*--------------------------------------------------------------
    * Created: DC 07/18/03 -- #21663  Add HQMA audit to these tables.
    * Modified:   EN 02/19/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    * Delete trigger on PR State Information
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
   	SELECT 'bPRSD', 'PRCo: ' + convert(char(2), d.PRCo) + ' State: ' + d.State + ' DLCode: ' + convert(char(3),d.DLCode),
              d.PRCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
           FROM deleted d
   	END
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR State Deduction Information (bPRSD)'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btPRSDi    Script Date: 7/18/2003 11:22:18 AM ******/
   
   CREATE      trigger [dbo].[btPRSDi] on [dbo].[bPRSD] for INSERT as
   

/*-----------------------------------------------------------------
    * Created by: MV 1/28/02
    * Modified:   DC 7/18/03 #21663 - Add HQMA audit to these tables.
    *				EN 02/19/03 - issue 23061  added isnull check, with (nolock), and dbo
    *											and corrected old style joins
    *
    * Insert trigger on PR States
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   /* validate PR Company */
   select @validcnt = count(*) from dbo.bHQCO c with (nolock) join inserted i on c.HQCo = i.PRCo
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Company# '
   	goto error
   	end
   
   /* validate DLCode */
   select @validcnt = count(*) from inserted i join dbo.PRDL c with (nolock) on i.PRCo = c.PRCo and i.DLCode = c.DLCode
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Dedn/Liab Code '
   	goto error
   	end
   
   /*validate CalCategory.*/
   select @validcnt = count(*) from dbo.bPRDL c with (nolock) join inserted i on c.PRCo = i.PRCo and i.DLCode = c.DLCode
       where c.CalcCategory not in ('S', 'A') 
   if @validcnt <> 0
   	begin
   	select @errmsg = 'DLCode calculation category must be S or A. '
   	goto error
   	end
   
   -- add HQ Master Audit entry   DC #21663
    if exists (select top 1 1 from inserted i join dbo.bPRCO a with (nolock) on a.PRCo = i.PRCo where a.AuditTaxes = 'Y')
     	begin
   	Insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 select 'bPRSD',  'PRCo: ' + convert(char(2), i.PRCo) + ' State: ' + i.State + ' DLCode: ' + convert(char(3),i.DLCode), i.PRCo, 'A',
   	 null, null, null, getdate(), SUSER_SNAME() from inserted i join dbo.bPRSD a on i.PRCo=a.PRCo and i.State=a.State and i.DLCode=a.DLCode
   	END
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR State item!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btPRSDu    Script Date: 7/18/2003 12:48:24 PM ******/
   
   
   
   CREATE   trigger [dbo].[btPRSDu] on [dbo].[bPRSD] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created: MV 1/28/02
    *  Modified:  DC  7/18/03  #21663 - Add HQMA audit to these tables.
    *				EN 02/19/03 - issue 23061  added isnull check, with (nolock), and dbo
    *											and corrected old style joins
    *                
    * Validate PRCo and DLCode and CalcCategory.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   
   if update(PRCo)
       begin
       select @validcnt = count(1) from dbo.bHQCO c with (nolock) join inserted i on c.HQCo = i.PRCo
   	if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Company# '
   	goto error
   	end
       end
   
   if update(DLCode)
       begin
       select @validcnt = count(1) from inserted i join dbo.PRDL c with (nolock) on i.PRCo = c.PRCo and i.DLCode = c.DLCode
   	if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Dedn/Liab Code '
   	goto error
   	end
       end
   
   /*validate CalCategory.*/
   select @validcnt = count(1) from dbo.bPRDL c with (nolock) join inserted i on c.PRCo = i.PRCo and i.DLCode = c.DLCode
       where c.CalcCategory not in ('S', 'A') 
   	if @validcnt <> 0
   	begin
   	select @errmsg = 'DLCode calculation category must be S or A. '
   	goto error
   	end
   
   
   -- add HQ Master Audit entry   DC #21663
   IF exists (select top 1 1 from inserted i join dbo.bPRCO a with (nolock) on a.PRCo = i.PRCo where a.AuditTaxes = 'Y')
     	begin
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRSD',  'PRCo: ' + convert(char(2), i.PRCo) + ' State: ' + i.State + ' DLCode: ' + convert(char(3),i.DLCode), i.PRCo, 'C','DLCode',
   		d.DLCode,i.DLCode,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State and i.DLCode=d.DLCode
          	where isnull(i.DLCode,'') <> isnull(d.DLCode,'')
     
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRSD',  'PRCo: ' + convert(char(2), i.PRCo) + ' State: ' + i.State + ' DLCode: ' + convert(char(3),i.DLCode), i.PRCo, 'C','BasedOn',
   		d.BasedOn,i.BasedOn,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State and i.DLCode=d.DLCode
          	where isnull(i.BasedOn,'') <> isnull(d.BasedOn,'')
   	END
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR State Items!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRSD] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRSD] ON [dbo].[bPRSD] ([PRCo], [State], [DLCode]) ON [PRIMARY]
GO
