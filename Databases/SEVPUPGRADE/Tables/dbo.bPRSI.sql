CREATE TABLE [dbo].[bPRSI]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NOT NULL,
[TaxID] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[TaxDedn] [dbo].[bEDLCode] NULL,
[TaxDiff] [dbo].[bYN] NOT NULL,
[UnempID] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[SUTALiab] [dbo].[bEDLCode] NULL,
[AccumHrsWks] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Contact] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Phone] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[PhoneExt] [varchar] (5) COLLATE Latin1_General_BIN NULL,
[TransId] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[C3] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[SuffixCode] [varchar] (5) COLLATE Latin1_General_BIN NULL,
[EstabId] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[StateId] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[TaxType] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[TaxEntity] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ControlId] [varchar] (7) COLLATE Latin1_General_BIN NULL,
[UnitId] [varchar] (5) COLLATE Latin1_General_BIN NULL,
[County] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[OutCounty] [varchar] (7) COLLATE Latin1_General_BIN NULL,
[DocControl] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[LocalCode1] [dbo].[bLocalCode] NULL,
[LocalCode2] [dbo].[bLocalCode] NULL,
[LocalCode3] [dbo].[bLocalCode] NULL,
[Plant] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[Branch] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[DLCode1] [dbo].[bEDLCode] NULL,
[DLCode2] [dbo].[bEDLCode] NULL,
[DisabilityPlanId] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[WagePlan] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[EMail] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[ExcludeOutOfStateSUTAWagesYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRSI_ExcludeOutOfStateSUTAWagesYN] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btPRSId    Script Date: 7/18/2003 11:00:53 AM ******/
   
   
   CREATE   trigger [dbo].[btPRSId] on [dbo].[bPRSI] for DELETE as
   

/*--------------------------------------------------------------
    * Created: GG 02/21/03 
    * Modified:   DC 7/18/03  -- #21663  Add HQMA audit to these tables.
    *				EN 02/19/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    * Delete trigger on PR State Information
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- check for State Detail Items
   if exists(select 1 from deleted d join dbo.bPRSD s with (nolock) on d.PRCo = s.PRCo and d.State = s.State)
   	begin
   	select @errmsg = 'State Detail items exist '
   	goto error
   	end
   
   -- add HQ Master Audit entry   DC #21663
    if exists (select * from deleted d join dbo.bPRCO a with (nolock) on a.PRCo = d.PRCo where a.AuditTaxes = 'Y')
     	begin
   	INSERT INTO bHQMA
   	     (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bPRSI', 'PRCo: ' + convert(char(10), d.PRCo) + ' State: ' + d.State,
              d.PRCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
           FROM deleted d
   	END
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR State Information (bPRSI)'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btPRSIi    Script Date: 7/17/2003 2:29:19 PM ******/
   CREATE     trigger [dbo].[btPRSIi] on [dbo].[bPRSI] for INSERT as
   

/*-----------------------------------------------------------------
    * Created: GG 02/21/03 
    * Modified: 	DANF 09/18/2003 - Correct null count on SutaLiab
    *				DC 7/17/03  - Add HQMA audit to these tables.
    *				EN 02/19/03 - issue 23061  added isnull check, with (nolock), and dbo
	*				EN 3/19/08 - #127081  modified HQST validation to include country
    *
    * Insert trigger on PR State Information
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int, @nullcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- validate PR Company 
   select @validcnt = count(*)
   from dbo.bHQCO c with (nolock)
   join inserted i on c.HQCo = i.PRCo
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid PR Company# '
   	goto error
   	end
   
   -- validate HQ State 
   select @validcnt = count(1) from inserted i join dbo.bHQCO c with (nolock) on c.HQCo=i.PRCo
		join dbo.bHQST s with (nolock) on c.DefaultCountry=s.Country and s.State=i.State
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid State '
   	goto error
   	end
   
   -- validate Tax Dedn 
   select @validcnt = count(*)
   from dbo.bPRDL d with (nolock)
   join inserted i on i.PRCo = d.PRCo and i.TaxDedn = d.DLCode
   where d.DLType = 'D' and d.CalcCategory in ('S', 'A')	-- must be deduction, State or Any
   
   select @nullcnt = count(*) from inserted where TaxDedn is null
   
   if @validcnt + @nullcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Tax Deduction Code '
   	goto error
   	end
   
   -- check for Tax Dedn uniqueness
   if exists(select 1 from inserted i join dbo.bPRSI s with (nolock) on i.PRCo = s.PRCo and i.TaxDedn = s.TaxDedn
   			where i.State <> s.State)
   	begin
   	select @errmsg = 'Tax Deduction Code can only be used on a single State '
   	goto error
   	end
   
   -- validate SUTA Liab 
   select @validcnt = count(*)
   from dbo.bPRDL d with (nolock)
   join inserted i on i.PRCo = d.PRCo and i.SUTALiab = d.DLCode
   where d.DLType = 'L' and d.CalcCategory in ('S', 'A') 	-- must be liability, State or Any
   
   select @nullcnt = count(*) from inserted where SUTALiab is null
   
   if @validcnt + @nullcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid SUTA Liability Code '
   	goto error
   	end
   
   -- check for SUTA Liab uniqueness
   if exists(select 1 from inserted i join dbo.bPRSI s with (nolock) on i.PRCo = s.PRCo and i.SUTALiab = s.SUTALiab
   			where i.State <> s.State)
   	begin
   	select @errmsg = 'SUTA Liability Code can only be used on a single State '
   	goto error
   	end
   
   -- add HQ Master Audit entry   DC #21663
    if exists (select * from inserted i join dbo.bPRCO a with (nolock) on a.PRCo = i.PRCo where a.AuditTaxes = 'Y')
     	begin
   	Insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 select 'bPRSI',  'PRCo: ' + convert(char(10), i.PRCo) + ' State: ' + i.State, i.PRCo, 'A',
   	 null, null, null, getdate(), SUSER_SNAME() from inserted i join dbo.bPRSI a on i.PRCo=a.PRCo and i.State=a.State
   	END
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR State Information!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btPRSIu    Script Date: 7/18/2003 12:50:10 PM ******/
   
   /****** Object:  Trigger dbo.btPRSIu    Script Date: 7/18/2003 10:55:00 AM ******/
   
   /****** Object:  Trigger dbo.btPRSIu    Script Date: 7/17/2003 2:24:36 PM ******/
   
   
   CREATE      trigger [dbo].[btPRSIu] on [dbo].[bPRSI] for UPDATE as
   

/*-----------------------------------------------------------------
    * Created: GG 02/21/03 
    * Modified:  DANF 09/18/2003 - Correct null count on SutaLiab
    *			  DC 7/18/03 - #21663  - Add HQMA audit to these tables.
    *				EN 02/19/03 - issue 23061  added isnull check, with (nolock), and dbo
    *			MV 12/04/12 - TK19844 added ExcludeOutOfStateSUTAWagesYN to HQMA
    *
    * Update trigger on PR State Information
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int, @nullcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- verify primary key not changed
   select @validcnt = count(*)
   from inserted i
   join deleted d on d.PRCo = i.PRCo and d.State = i.State
   if @validcnt <> @numrows
       begin
    	select @errmsg = 'Cannot change PR Company # or State '
    	goto error
    	end
   
   if update(TaxDedn)
   	begin
   	-- validate Tax Dedn 
   	select @validcnt = count(*)
   	from dbo.bPRDL d with (nolock)
   	join inserted i on i.PRCo = d.PRCo and i.TaxDedn = d.DLCode
   	where d.DLType = 'D' and d.CalcCategory in ('S', 'A')	-- must be deduction, State or Any
   
   	select @nullcnt = count(*) from inserted where TaxDedn is null
   
   	if @validcnt + @nullcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid Tax Deduction Code '
   		goto error
   		end
   
   	-- check for Tax Dedn uniqueness
   	if exists(select 1 from inserted i join dbo.bPRSI s with (nolock) on i.PRCo = s.PRCo and i.TaxDedn = s.TaxDedn
   				where i.State <> s.State)
   		begin
   		select @errmsg = 'Tax Deduction Code can only be used on a single State '
   		goto error
   		end
   	end
   
   if update(SUTALiab)
   	begin
   	-- validate SUTA Liab 
   	select @validcnt = count(*)
   	from dbo.bPRDL d with (nolock)
   	join inserted i on i.PRCo = d.PRCo and i.SUTALiab = d.DLCode
   	where d.DLType = 'L' and d.CalcCategory in ('S', 'A') 	-- must be liability, State or Any
   	
   	select @nullcnt = count(*) from inserted where SUTALiab is null
   	
   	if @validcnt + @nullcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid SUTA Liability Code '
   		goto error
   		end
   
   	-- check for SUTA Liab uniqueness
   	if exists(select 1 from inserted i join dbo.bPRSI s with (nolock) on i.PRCo = s.PRCo and i.SUTALiab = s.SUTALiab
   				where i.State <> s.State)
   		begin
   		select @errmsg = 'SUTA Liability Code can only be used on a single State '
   		goto error
   		end
   	end
   
    /* add HQ Master Audit entry */
   IF exists (select top 1 1 from inserted i join dbo.bPRCO a with (nolock) on a.PRCo = i.PRCo where a.AuditTaxes = 'Y')
     	begin
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRSI',  'PRCo: ' + convert(char(10), i.PRCo) + ' State: ' + i.State, i.PRCo, 'C','TaxID',
   		d.TaxID,i.TaxID,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State
          	where isnull(i.TaxID,'') <> isnull(d.TaxID,'')
     
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRSI',  'PRCo: ' + convert(char(10), i.PRCo) + ' State: ' + i.State, i.PRCo, 'C','TaxDedn',
   		d.TaxDedn,i.TaxDedn,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State
          	where isnull(i.TaxDedn,'') <> isnull(d.TaxDedn,'')
   
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRSI',  'PRCo: ' + convert(char(10), i.PRCo) + ' State: ' + i.State, i.PRCo, 'C','TaxDiff',
   		d.TaxDiff,i.TaxDiff,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State
          	where isnull(i.TaxDiff,'') <> isnull(d.TaxDiff,'')
   
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRSI',  'PRCo: ' + convert(char(10), i.PRCo) + ' State: ' + i.State, i.PRCo, 'C','UnempID',
   		d.UnempID,i.UnempID,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State
          	where isnull(i.UnempID,'') <> isnull(d.UnempID,'')
   
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRSI',  'PRCo: ' + convert(char(10), i.PRCo) + ' State: ' + i.State, i.PRCo, 'C','SUTALiab',
   		d.SUTALiab,i.SUTALiab,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State
          	where isnull(i.SUTALiab,'') <> isnull(d.SUTALiab,'')
   
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRSI',  'PRCo: ' + convert(char(10), i.PRCo) + ' State: ' + i.State, i.PRCo, 'C','AccumHrsWks',
   		d.AccumHrsWks,i.AccumHrsWks,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State
          	where isnull(i.AccumHrsWks,'') <> isnull(d.AccumHrsWks,'')
   
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRSI',  'PRCo: ' + convert(char(10), i.PRCo) + ' State: ' + i.State, i.PRCo, 'C','Contact',
   		d.Contact,i.Contact,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State
          	where isnull(i.Contact,'') <> isnull(d.Contact,'')
   
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRSI',  'PRCo: ' + convert(char(10), i.PRCo) + ' State: ' + i.State, i.PRCo, 'C','Phone',
   		d.Phone,i.Phone,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State
          	where isnull(i.Phone,'') <> isnull(d.Phone,'')
   
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRSI',  'PRCo: ' + convert(char(10), i.PRCo) + ' State: ' + i.State, i.PRCo, 'C','PhoneExt',
   		d.PhoneExt,i.PhoneExt,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State
          	where isnull(i.PhoneExt,'') <> isnull(d.PhoneExt,'')
   
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRSI',  'PRCo: ' + convert(char(10), i.PRCo) + ' State: ' + i.State, i.PRCo, 'C','TransId',
   		d.TransId,i.TransId,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State
          	where isnull(i.TransId,'') <> isnull(d.TransId,'')
   
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRSI',  'PRCo: ' + convert(char(10), i.PRCo) + ' State: ' + i.State, i.PRCo, 'C','C3',
   		d.C3,i.C3,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State
          	where isnull(i.C3,'') <> isnull(d.C3,'')
   
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRSI',  'PRCo: ' + convert(char(10), i.PRCo) + ' State: ' + i.State, i.PRCo, 'C','SuffixCode',
   		d.SuffixCode,i.SuffixCode,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State
          	where isnull(i.SuffixCode,'') <> isnull(d.SuffixCode,'')
   
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRSI',  'PRCo: ' + convert(char(10), i.PRCo) + ' State: ' + i.State, i.PRCo, 'C','EstabId',
   		d.EstabId,i.EstabId,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State
          	where isnull(i.EstabId,'') <> isnull(d.EstabId,'')
   
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRSI',  'PRCo: ' + convert(char(10), i.PRCo) + ' State: ' + i.State, i.PRCo, 'C','StateId',
   		d.StateId,i.StateId,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State
          	where isnull(i.StateId,'') <> isnull(d.StateId,'')
   
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRSI',  'PRCo: ' + convert(char(10), i.PRCo) + ' State: ' + i.State, i.PRCo, 'C','TaxType',
   		d.TaxType,i.TaxType,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State
          	where isnull(i.TaxType,'') <> isnull(d.TaxType,'')
   
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRSI',  'PRCo: ' + convert(char(10), i.PRCo) + ' State: ' + i.State, i.PRCo, 'C','TaxEntity',
   		d.TaxEntity,i.TaxEntity,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State
          	where isnull(i.TaxEntity,'') <> isnull(d.TaxEntity,'')
   
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRSI',  'PRCo: ' + convert(char(10), i.PRCo) + ' State: ' + i.State, i.PRCo, 'C','ControlId',
   		d.ControlId,i.ControlId,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State
          	where isnull(i.ControlId,'') <> isnull(d.ControlId,'')
   
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRSI',  'PRCo: ' + convert(char(10), i.PRCo) + ' State: ' + i.State, i.PRCo, 'C','UnitId',
   		d.UnitId,i.UnitId,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State
          	where isnull(i.UnitId,'') <> isnull(d.UnitId,'')
   
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRSI',  'PRCo: ' + convert(char(10), i.PRCo) + ' State: ' + i.State, i.PRCo, 'C','County',
   		d.County,i.County,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State
          	where isnull(i.County,'') <> isnull(d.County,'')
   
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRSI',  'PRCo: ' + convert(char(10), i.PRCo) + ' State: ' + i.State, i.PRCo, 'C','OutCounty',
   		d.OutCounty,i.OutCounty,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State
          	where isnull(i.OutCounty,'') <> isnull(d.OutCounty,'')
   
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRSI',  'PRCo: ' + convert(char(10), i.PRCo) + ' State: ' + i.State, i.PRCo, 'C','DocControl',
   		d.DocControl,i.DocControl,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State
          	where isnull(i.DocControl,'') <> isnull(d.DocControl,'')
   
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRSI',  'PRCo: ' + convert(char(10), i.PRCo) + ' State: ' + i.State, i.PRCo, 'C','LocalCode1',
   		d.LocalCode1,i.LocalCode1,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State
          	where isnull(i.LocalCode1,'') <> isnull(d.LocalCode1,'')
   
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRSI',  'PRCo: ' + convert(char(10), i.PRCo) + ' State: ' + i.State, i.PRCo, 'C','LocalCode2',
   		d.LocalCode2,i.LocalCode2,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State
          	where isnull(i.LocalCode2,'') <> isnull(d.LocalCode2,'')
   
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRSI',  'PRCo: ' + convert(char(10), i.PRCo) + ' State: ' + i.State, i.PRCo, 'C','LocalCode3',
   		d.LocalCode3,i.LocalCode3,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State
          	where isnull(i.LocalCode3,'') <> isnull(d.LocalCode3,'')
   
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRSI',  'PRCo: ' + convert(char(10), i.PRCo) + ' State: ' + i.State, i.PRCo, 'C','Plant',
   		d.Plant,i.Plant,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State
          	where isnull(i.Plant,'') <> isnull(d.Plant,'')
   
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRSI',  'PRCo: ' + convert(char(10), i.PRCo) + ' State: ' + i.State, i.PRCo, 'C','Branch',
   		d.Branch,i.Branch,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo and i.State = d.State
          	where isnull(i.Branch,'') <> isnull(d.Branch,'')
          	
    INSERT INTO dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bPRSI',  'PRCo: ' + convert(char(10), i.PRCo) + ' State: ' + i.State, i.PRCo, 'C','ExcludeOutOfStateSUTAWagesYN',
   		d.ExcludeOutOfStateSUTAWagesYN,i.ExcludeOutOfStateSUTAWagesYN,getdate(), SUSER_SNAME()
   	FROM inserted i
    JOIN deleted d on i.PRCo = d.PRCo and i.State = d.State
    WHERE isnull(i.ExcludeOutOfStateSUTAWagesYN,'') <> isnull(d.ExcludeOutOfStateSUTAWagesYN,'')

     
          end
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR State Information!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRSI] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRSI] ON [dbo].[bPRSI] ([PRCo], [State]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRSI].[TaxDiff]'
GO
