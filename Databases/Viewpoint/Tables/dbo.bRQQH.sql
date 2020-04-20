CREATE TABLE [dbo].[bRQQH]
(
[RQCo] [dbo].[bCompany] NOT NULL,
[Quote] [int] NOT NULL,
[UserName] [dbo].[bVPUserName] NOT NULL,
[CreateDate] [dbo].[bDate] NOT NULL,
[Locked] [dbo].[bYN] NOT NULL,
[Description] [dbo].[bTransDesc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[InUseBy] [dbo].[bVPUserName] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bRQQH] ADD 
CONSTRAINT [biRQQH] PRIMARY KEY CLUSTERED  ([RQCo], [Quote]) WITH (FILLFACTOR=90) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bRQQH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btRQQHd    Script Date: 3/5/2004 7:27:55 AM ******/
    CREATE     trigger [dbo].[btRQQHd] on [dbo].[bRQQH] for DELETE as
    

/*-----------------------------------------------------------------
     *  Created: DC 3/5/2004
     *  Modified: DC 1/9/2009  #130129 - Combine RQ and PO into a single module
     *
     *
     *  Delete trigger for bRQQH.  
     *  Inserts into HQ Master Audit entry.
     *
     */----------------------------------------------------------------
      declare @errmsg varchar(255), @numrows int 
    
      if @@rowcount = 0 return
      --set nocount on
    
    
    /* check Quote Line */
        if exists(select top 1 0 from deleted d join bRQQL a on a.RQCo = d.RQCo and a.Quote = d.Quote)
          begin
          select @errmsg = 'Cannot DELETE bRQQH because bRQQL exists.'
          goto error
          end
    
    /* check Vendor Quote */
        if exists(select top 1 0 from deleted d join bRQVQ a on a.RQCo = d.RQCo and a.Quote = d.Quote)
          begin
          select @errmsg = 'Cannot DELETE bRQQH because bRQVQ exists.'
          goto error
          end
    
    /* Audit Quote Header deletions */
        if exists(select top 1 0 from deleted d join bPOCO a on a.POCo = d.RQCo where a.AuditQuote = 'Y')
          BEGIN
          insert into bHQMA
      	(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	  select 'bRQQH', 'RQCo: ' + convert(varchar(3),RQCo) + ' Quote: ' + convert(varchar(10),Quote),
    	   RQCo, 'D', null, null, null, getdate(), SUSER_SNAME()
    	   from deleted d
        if @@rowcount <> @numrows
    	begin
    	select @errmsg = 'Unable to update HQ Master Audit'
    	goto error
    	end
          END
    
    return
    error:
    	select @errmsg = @errmsg + ' - cannot delete Quote Header!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
    
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btRQQHi    Script Date: 3/5/2004 8:00:51 AM ******/
    CREATE      trigger [dbo].[btRQQHi] on [dbo].[bRQQH] for INSERT as
    

/*-----------------------------------------------------------------
     *  Created: DC 3/05/04
     *  Modified: DC 1/9/2009  #130129  -Combine RQ and PO into a single module
     *
     *
     *  Validates:	RQCo
     *  HQ Master Audit entry.
     */----------------------------------------------------------------
      declare @errmsg varchar(255), @validcnt int, @numrows int
    
    SELECT @numrows = @@rowcount
    IF @numrows = 0 return
    --SET nocount on
    
    /* validate RQ Company */
    SELECT @validcnt = count(1) FROM bPOCO c WITH (NOLOCK)
    	JOIN inserted i ON c.POCo = i.RQCo
    IF @validcnt <> @numrows
    	BEGIN
    	SELECT @errmsg = 'Invalid PO Company'
    	GOTO error
    	END
    
    /* Audit Quote Header Inserts */
        if exists(select top 1 0 from inserted i join bPOCO a WITH (NOLOCK) on a.POCo = i.RQCo where a.AuditQuote = 'Y')
          BEGIN
          insert into bHQMA
      	(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	  select 'bRQQH', 'RQCo: ' + convert(varchar(3),RQCo) + ' Quote: ' + convert(varchar(10),Quote),
    	   RQCo, 'A', null, null, null, getdate(), SUSER_SNAME()
    	   from inserted i
        if @@rowcount <> @numrows
    	begin
    	select @errmsg = 'Unable to update HQ Master Audit'
    	goto error
    	end
          END
    
    return
    
    error:
        SELECT @errmsg = @errmsg +  ' - cannot insert Quote Header!'
        RAISERROR(@errmsg, 11, -1);
        rollback transaction
    
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btRQQHu    Script Date: 3/5/2004 8:27:40 AM ******/
    CREATE      trigger [dbo].[btRQQHu] on [dbo].[bRQQH] for UPDATE as
    

/*-----------------------------------------------------------------
     *  Created: DC 3/5/2004
     *  Modified: DC 1/9/2009 #130129 - Combine RQ and PO into a single module
     *
     *
     *  Update trigger for bRQQH.  
     *
     *  Validate:  Key field changes not allowed
     *  
     *  HQ Master Audit entry.
     *
     */----------------------------------------------------------------
     declare @numrows int, @validcnt int, @errmsg varchar(255)
    
      select @numrows = @@rowcount
      if @numrows = 0 return
      --set nocount on
    
      /* check for key changes */
      select @validcnt = count(1) from deleted d, inserted i
     	where d.RQCo = i.RQCo and d.Quote = i.Quote
      if @numrows <> @validcnt
     	begin
     	select @errmsg = 'Cannot change RQ Company or Quote'
     	goto error
     	end
    
    -- add HQ Master Audit entry
      if exists(select top 1 0 from inserted i join bPOCO a with (NOLOCK) on a.POCo = i.RQCo where a.AuditQuote = 'Y')
       BEGIN 
       /* Insert records into HQMA for changes made to audited fields */
       if update(Description)
       insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
       	select 'bRQQH', 'RQCo: ' + convert(char(3),i.RQCo) + ' Quote: ' + convert(char(10), i.Quote),
    	 i.RQCo, 'C', 'Description', isnull(d.Description,''), isnull(i.Description,''),getdate(), SUSER_SNAME()
     	from inserted i join deleted d on i.RQCo = d.RQCo and i.Quote = d.Quote
     	where isnull(i.Description,0) <> isnull(d.Description,0)
       if update(UserName)
       insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
       	select 'bRQQH', 'RQCo: ' + convert(char(3),i.RQCo) + ' Quote: ' + convert(char(10), i.Quote),
    	 i.RQCo, 'C', 'UserName', isnull(d.UserName,''), isnull(i.UserName,''),getdate(), SUSER_SNAME()
     	from inserted i join deleted d on i.RQCo = d.RQCo and i.Quote = d.Quote
     	where isnull(i.UserName,0) <> isnull(d.UserName,0)
       if update(CreateDate)
       insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
       	select 'bRQQH', 'RQCo: ' + convert(char(3),i.RQCo) + ' Quote: ' + convert(char(10), i.Quote),
    	 i.RQCo, 'C', 'CreateDate', isnull(d.CreateDate,''), isnull(i.CreateDate,''),getdate(), SUSER_SNAME()
     	from inserted i join deleted d on i.RQCo = d.RQCo and i.Quote = d.Quote
     	where isnull(i.CreateDate,0) <> isnull(d.CreateDate,0)
       END
    
    
    return
    
    error:
    	select @errmsg = @errmsg + ' - cannot update Quote Header!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
    
   
   
   
  
 



GO

EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bRQQH].[Locked]'
GO
