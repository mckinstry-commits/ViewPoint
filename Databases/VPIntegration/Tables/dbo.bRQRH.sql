CREATE TABLE [dbo].[bRQRH]
(
[RQCo] [dbo].[bCompany] NOT NULL,
[RQID] [dbo].[bRQ] NOT NULL,
[Source] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Requestor] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[RecDate] [dbo].[bDate] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[InUseBy] [dbo].[bVPUserName] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btRQRHd    Script Date: 3/1/2004 2:17:04 PM ******/
    CREATE       trigger [dbo].[btRQRHd] on [dbo].[bRQRH] for DELETE as
    

/*-----------------------------------------------------------------
     *  Created: DC 3/1/2004
     *  Modified: DC 1/9/2009 #130129 - Combine RQ and PO into a single module
     *
     *
     *  Delete trigger for bRQRH.  
     *
     *  Validates:  Checks for existance of RQRL
     *
     *  HQ Master Audit entry.
     *
     */----------------------------------------------------------------
    declare @errmsg varchar(255), @validcnt int, @numrows int 
    
    if @@rowcount = 0 return
    set nocount on
    
    
    /* check RQ Line */
        if exists(select top 1 0 from deleted d join bRQRL a with (NOLOCK) on a.RQCo = d.RQCo and a.RQID = d.RQID)
          begin
          select @errmsg = 'Cannot DELETE bRQRH because bRQRL exists.'
          goto error
          end
    
   
    /* Audit RQ Header deletions */
        if exists(select top 1 0 from deleted d join bPOCO a with (NOLOCK) on a.POCo = d.RQCo where a.AuditRQ = 'Y')
          BEGIN
          insert into bHQMA
      	(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	  select 'bRQRH', 'RQCo: ' + convert(varchar(3),RQCo) + ' RQID: ' + convert(varchar(10),RQID),
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
    	select @errmsg = @errmsg + ' - cannot delete RQ Header!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
    
    
    
    
    
    
    
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btRQRHi    Script Date: 2/25/2004 1:43:53 PM ******/
    CREATE       trigger [dbo].[btRQRHi] on [dbo].[bRQRH] for INSERT as
    

/*-----------------------------------------------------------------
     *  Created: DC 2/25/04
     *  Modified: DC 1/9/2009  #130129 - Combine RQ and PO into a single module
     *
     *
     *  Validates RQCo.  
     *  HQ Master Audit entry.
     */----------------------------------------------------------------
      declare @errmsg varchar(255), @validcnt int, @numrows int
    
    SELECT @numrows = @@rowcount
    IF @numrows = 0 return
    SET nocount on
    
    /* validate RQ Company */
    SELECT @validcnt = count(1) FROM bPOCO c WITH (NOLOCK)
    	JOIN inserted i ON c.POCo = i.RQCo
    IF @validcnt <> @numrows
    	BEGIN
    	SELECT @errmsg = 'Invalid RQ Company'
    	GOTO error
    	END
    
    /* Audit RQ Header Inserts */
        if exists(select top 1 0 from inserted i join bPOCO a WITH (NOLOCK) on a.POCo = i.RQCo where a.AuditRQ = 'Y')
          BEGIN
          insert into bHQMA
      	(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	  select 'bRQRH', 'RQCo: ' + convert(varchar(3),RQCo) + ' RQID: ' + convert(varchar(10),RQID),
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
        SELECT @errmsg = @errmsg +  ' - cannot insert RQ Header!'
        RAISERROR(@errmsg, 11, -1);
        rollback transaction
    
    
    
    
    
    
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btRQRHu    Script Date: 7/14/2004 11:28:00 AM ******/
    
    
    /****** Object:  Trigger dbo.btRQRHu    Script Date: 3/1/2004 3:06:44 PM ******/
    CREATE       trigger [dbo].[btRQRHu] on [dbo].[bRQRH] for UPDATE as
    

/*-----------------------------------------------------------------
     *  Created: DC 3/1/2004
     *  Modified: DC 1/9/2009  #130129 - Combine RQ and PO into a single module
     *
     *
     *  Update trigger for bRQRH.  
     *  Validate:  Key field changes not allowed
     * 
     *  HQ Master Audit entry.
     *
     */----------------------------------------------------------------
     declare @numrows int, @validcnt int, @errmsg varchar(255)
    
      select @numrows = @@rowcount
      if @numrows = 0 return
      set nocount on
    
      /* check for key changes */
      select @validcnt = count(1) from deleted d, inserted i
     	where d.RQCo = i.RQCo and d.RQID = i.RQID
      if @numrows <> @validcnt
     	begin
     	select @errmsg = 'Cannot change RQ Company or RQID'
     	goto error
     	end
    
    -- add HQ Master Audit entry
      if exists(select top 1 0 from inserted i join bPOCO a with (NOLOCK) on a.POCo = i.RQCo where a.AuditRQ = 'Y')
       BEGIN 
       /* Insert records into HQMA for changes made to audited fields */
       if update(Source)
       insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
       	select 'bRQRH', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID),
    	 i.RQCo, 'C', 'Source', isnull(d.Source,''), isnull(i.Source,''),getdate(), SUSER_SNAME()
     	from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID
     	where isnull(i.Source,0) <> isnull(d.Source,0)
       if update(Requestor)
       insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
       	select 'bRQRH', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID),
    	 i.RQCo, 'C', 'Requestor', isnull(d.Requestor,''), isnull(i.Requestor,''),getdate(), SUSER_SNAME()
     	from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID
     	where isnull(i.Requestor,0) <> isnull(d.Requestor,0)
       if update(RecDate)
       insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
       	select 'bRQRH', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID),
    	 i.RQCo, 'C', 'RecDate', isnull(d.RecDate,''), isnull(i.RecDate,''),getdate(), SUSER_SNAME()
     	from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID
     	where isnull(i.RecDate,0) <> isnull(d.RecDate,0)
       if update(Description)
       insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
       	select 'bRQRH', 'RQCo: ' + convert(char(3),i.RQCo) + ' RQID: ' + convert(char(10), i.RQID),
    	 i.RQCo, 'C', 'Description', isnull(d.Description,''), isnull(i.Description,''),getdate(), SUSER_SNAME()
     	from inserted i join deleted d on i.RQCo = d.RQCo and i.RQID = d.RQID
     	where isnull(i.Description,0) <> isnull(d.Description,0)
       END
    
    
    return
    
    error:
    	select @errmsg = @errmsg + ' - cannot update RQ Header!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
    
    
    
    
    
    
    
    
    
   
   
   
  
 



GO
ALTER TABLE [dbo].[bRQRH] ADD CONSTRAINT [biRQRH] PRIMARY KEY CLUSTERED  ([RQCo], [RQID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bRQRH] ([KeyID]) ON [PRIMARY]
GO
