CREATE TABLE [dbo].[bPRLI]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[LocalCode] [dbo].[bLocalCode] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[TaxID] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NOT NULL,
[TaxDedn] [dbo].[bEDLCode] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[CalcOpt] [tinyint] NOT NULL CONSTRAINT [DF_bPRLI_CalcOpt] DEFAULT ((0)),
[TaxType] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPRLI_TaxType] DEFAULT ('C'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[TaxEntity] [char] (10) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPRLI] ON [dbo].[bPRLI] ([PRCo], [LocalCode]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRLI] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btPRLId    Script Date: 7/18/2003 2:41:40 PM ******/
   
   CREATE    trigger [dbo].[btPRLId] on [dbo].[bPRLI] for DELETE as
   

/*-----------------------------------------------------------------
    *	Created: GG 07/22/02
    *	Modified:  DC 07/18/03  #21663 - Add HQMA audit to these tables.
    *				EN 02/18/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    *	Delete trigger for bPRLI (PR Local Info)
    *
    */----------------------------------------------------------------
   
   declare @errmsg varchar(255), @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   if exists(select 1 from dbo.bPRLD l with (nolock) join deleted d on l.PRCo=d.PRCo and l.LocalCode=d.LocalCode)
    	begin
    	select @errmsg = 'Local Code detail still exists'
    	goto error
    	end
   if exists(select 1 from dbo.bPREH e with (nolock) join deleted d on e.PRCo=d.PRCo and e.LocalCode=d.LocalCode)
    	begin
    	select @errmsg = 'Local Code assigned to one or more Employees'
    	goto error
    	end
   if exists(select 1 from dbo.bPRWT e with (nolock) join deleted d on e.PRCo=d.PRCo and e.LocalCode=d.LocalCode)
    	begin
    	select @errmsg = 'W2 State/Local detail(s) exist for this Local Code'
    	goto error
    	end
   if exists(select 1 from dbo.bPRWL e with (nolock) join deleted d on e.PRCo=d.PRCo and e.LocalCode=d.LocalCode)
    	begin
    	select @errmsg = 'W2 State/Local Employee detail still exists for this Local Code'
    	goto error
    	end
   
   -- add HQ Master Audit entry   DC #21663
   if exists (select * from deleted d join dbo.bPRCO a with (nolock) on a.PRCo = d.PRCo where a.AuditTaxes = 'Y')
     	begin
   	INSERT INTO dbo.bHQMA
   	     (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bPRLI', 'PRCo: ' + convert(char(2), d.PRCo) + ' LocalCode: ' + convert(char(10),d.LocalCode),
              d.PRCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
           FROM deleted d
   	END
   
   
   return
   
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR Local Code info!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btPRLIi    Script Date: 7/18/2003 1:29:27 PM ******/
   
   
   CREATE   trigger [dbo].[btPRLIi] on [dbo].[bPRLI] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created: GG 07/22/02
    * 	Modified:   DC 7/18/03 #21663 - Add HQMA audit to these tables.
    *				EN 02/18/03 - issue 23061  added isnull check, with (nolock), and dbo
	*				EN 3/19/08 - #127081  modified HQST validation to include country
    *
    *	This trigger validates insertion in bPRLI (PR Local Information)
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int, @nullcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- PR Company
   select @validcnt = count(1) from dbo.bHQCO c with (nolock) join inserted i on c.HQCo = i.PRCo
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Company# '
   	goto error
   	end
   -- State 
   select @validcnt = count(1) from inserted i join dbo.bHQCO c with (nolock) on c.HQCo=i.PRCo
		join dbo.bHQST s with (nolock) on c.DefaultCountry=s.Country and s.State=i.State
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid State code '
   	goto error
   	end
   -- Tax Deduction - may be null 
   select @nullcnt = count(1) from inserted where TaxDedn is null
   select @validcnt = count(1)
   from dbo.bPRDL d with (nolock)
   join inserted i on d.PRCo = i.PRCo and d.DLCode = i.TaxDedn
   where d.DLType = 'D'
   if @validcnt + @nullcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Tax Deduction code '
   	goto error
   	end
   -- Tax Type
   if exists(select 1 from inserted where TaxType not in ('C','D','E','F'))
   	begin
   	select @errmsg = 'Invalid Tax Type, must be ''C'',''D'',''E'', or ''F'''
   	goto error
   	end
   
   -- add HQ Master Audit entry   DC #21663
    if exists (select top 1 1 from inserted i join dbo.bPRCO a with (nolock) on a.PRCo = i.PRCo where a.AuditTaxes = 'Y')
     	begin
   	Insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 select 'bPRLI',  'PRCo: ' + convert(char(2), i.PRCo) + ' LocalCode: ' + convert(char(10),i.LocalCode), i.PRCo, 'A',
   	 null, null, null, getdate(), SUSER_SNAME() from inserted i join dbo.bPRLI a on i.PRCo=a.PRCo and i.LocalCode=a.LocalCode
   	END
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Local Info!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
   
   CREATE   trigger [dbo].[btPRLIu] on [dbo].[bPRLI] for UPDATE as
/*-----------------------------------------------------------------
    * Created: GG 07/22/02
    * Modified: DC 7/18/03 #21663  - Add HQMA audit to these tables.
    *				EN 02/18/03 - issue 23061  added isnull check, with (nolock), and dbo
	*				EN 03/19/08 - #127081  modified HQST validation to include country
	*				KK 10/28/11 - TK-09086 #144794 Removed TaxDiff and ResCalc and added code for CalcOpt
    *
    *	This trigger validates updates to bPRLI (PR Local Info)
    *
    *	
    */----------------------------------------------------------------
    
   declare @errmsg varchar(255), @numrows int, @validcnt int, @nullcnt int
    
   select @numrows = @@rowcount
   if @numrows = 0 return
    
   set nocount on
    
   -- PR Company 
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
    
   -- State 
   if update(State)
   	begin
    select @validcnt = count(1) from inserted i join dbo.bHQCO c with (nolock) on c.HQCo=i.PRCo
		join dbo.bHQST s with (nolock) on c.DefaultCountry=s.Country and s.State=i.State
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid State code '
   		goto error
   		end
   	end
   -- Tax Deduction - may be null 
   if update(TaxDedn)
   	begin
   	select @nullcnt = count(1) from inserted where TaxDedn is null
   	select @validcnt = count(1)
   	from dbo.bPRDL d with (nolock)
   	join inserted i on d.PRCo = i.PRCo and d.DLCode = i.TaxDedn
   	where d.DLType = 'D'
   	if @validcnt + @nullcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid Tax Deduction code '
   		goto error
   		end
   	end
   -- Tax Type
   if update(TaxType)
   	begin
   	if exists(select 1 from inserted where TaxType not in ('C','D','E','F'))
   		begin
   		select @errmsg = 'Invalid Tax Type, must be ''C'',''D'',''E'', or ''F'''
   		goto error
   		end
   	end
   
   -- add HQ Master Audit entry   DC #21663
   IF exists (select top 1 1 from inserted i join dbo.bPRCO a with (nolock) on a.PRCo = i.PRCo where a.AuditTaxes = 'Y')
     	begin
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRLI',  'PRCo: ' + convert(char(2), i.PRCo) + ' LocalCode: ' + convert(char(10),i.LocalCode), i.PRCo, 'C','Description',
   		d.Description,i.Description,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.LocalCode = d.LocalCode
          	where isnull(i.Description,'') <> isnull(d.Description,'')
     
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRLI',  'PRCo: ' + convert(char(2), i.PRCo) + ' LocalCode: ' + convert(char(10),i.LocalCode), i.PRCo, 'C','TaxID',
   		d.TaxID,i.TaxID,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.LocalCode = d.LocalCode
          	where isnull(i.TaxID,'') <> isnull(d.TaxID,'')
   
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRLI',  'PRCo: ' + convert(char(2), i.PRCo) + ' LocalCode: ' + convert(char(10),i.LocalCode), i.PRCo, 'C','State',
   		d.State,i.State,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.LocalCode = d.LocalCode
          	where isnull(i.State,'') <> isnull(d.State,'')
   
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRLI',  'PRCo: ' + convert(char(2), i.PRCo) + ' LocalCode: ' + convert(char(10),i.LocalCode), i.PRCo, 'C','TaxDedn',
   		d.TaxDedn,i.TaxDedn,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.LocalCode = d.LocalCode
          	where isnull(i.TaxDedn,'') <> isnull(d.TaxDedn,'')
   
   	--insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	--select 'bPRLI',  'PRCo: ' + convert(char(2), i.PRCo) + ' LocalCode: ' + convert(char(10),i.LocalCode), i.PRCo, 'C','ResCalc',
   	--	d.ResCalc,i.ResCalc,getdate(), SUSER_SNAME()
   	--from inserted i
    --       join deleted d on i.PRCo = d.PRCo and i.LocalCode = d.LocalCode
    --      	where isnull(i.ResCalc,'') <> isnull(d.ResCalc,'')
   
   	--insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	--select 'bPRLI',  'PRCo: ' + convert(char(2), i.PRCo) + ' LocalCode: ' + convert(char(10),i.LocalCode), i.PRCo, 'C','TaxDiff',
   	--	d.TaxDiff,i.TaxDiff,getdate(), SUSER_SNAME()
   	--from inserted i
    --       join deleted d on i.PRCo = d.PRCo and i.LocalCode = d.LocalCode
    --      	where isnull(i.TaxDiff,'') <> isnull(d.TaxDiff,'')
    
    insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRLI',  'PRCo: ' + convert(char(2), i.PRCo) + ' LocalCode: ' + convert(char(10),i.LocalCode), i.PRCo, 'C','CalcOpt',
   		d.CalcOpt,i.CalcOpt,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.LocalCode = d.LocalCode
          	where isnull(i.CalcOpt,'') <> isnull(d.CalcOpt,'')
     
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRLI',  'PRCo: ' + convert(char(2), i.PRCo) + ' LocalCode: ' + convert(char(10),i.LocalCode), i.PRCo, 'C','TaxType',
   		d.TaxType,i.TaxType,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.LocalCode = d.LocalCode
          	where isnull(i.TaxType,'') <> isnull(d.TaxType,'')
   	END
   
   
   return
   
   error:
     	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Local Info!'
     	RAISERROR(@errmsg, 11, -1);
     	rollback transaction
     
     
     
    
    
    
   
   
   
   
   
   
  
 



GO
