CREATE TABLE [dbo].[bPRFI]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[TaxDedn] [dbo].[bEDLCode] NOT NULL,
[FUTALiab] [dbo].[bEDLCode] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[MiscFedDL1] [dbo].[bEDLCode] NULL,
[MiscFedDL2] [dbo].[bEDLCode] NULL,
[MiscFedDL3] [dbo].[bEDLCode] NULL,
[MiscFedDL4] [dbo].[bEDLCode] NULL,
[MiscFedDL5] [dbo].[bEDLCode] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btPRFId    Script Date: 7/21/2003 10:40:55 AM ******/
   CREATE     trigger [dbo].[btPRFId] on [dbo].[bPRFI] for DELETE as
   

/*-----------------------------------------------------------------
    *	Created: DC 07/18/03  #21663 - Add HQMA audit to these tables.
    *	Modified:  EN 02/18/03 - issue 23061  added with (nolock), and dbo
    *
    *	Delete trigger for bPRFI (PR Federal Info)
    *
    */----------------------------------------------------------------
   
   set nocount on
   
   -- add HQ Master Audit entry   DC #21663
   if exists (select * from deleted d join dbo.bPRCO a with (nolock) on a.PRCo = d.PRCo where a.AuditTaxes = 'Y')
     	begin
   	INSERT INTO dbo.bHQMA
   	     (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bPRFI', 'PRCo: ' + convert(char(2), d.PRCo),
              d.PRCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
           FROM deleted d
   	END
   
   return
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btPRLIi    Script Date: 7/21/2003 9:56:21 AM ******/
   CREATE    trigger [dbo].[btPRFIi] on [dbo].[bPRFI] for INSERT as
   

/*-----------------------------------------------------------------
    *	Created: DC 07/21/03  #21663 - Add HQMA audit to these tables.
    *	Modified:  EN 02/18/03 - issue 23061  added with (nolock), and dbo
    *
    *	Insert trigger for bPRFI (PR Federal Info)
    *
    */----------------------------------------------------------------
   
   set nocount on
   
   -- add HQ Master Audit entry   DC #21663
   if exists (select * from inserted i join dbo.bPRCO a with (nolock) on a.PRCo = i.PRCo where a.AuditTaxes = 'Y')
     	begin
   	INSERT INTO dbo.bHQMA
   	     (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bPRFI', 'PRCo: ' + convert(char(2), i.PRCo),
              i.PRCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
           FROM inserted i
   	END
   
   return
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btPRLIu    Script Date: 7/21/2003 10:45:08 AM ******/
   CREATE   trigger [dbo].[btPRFIu] on [dbo].[bPRFI] for UPDATE as
    

/*-----------------------------------------------------------------
    * Created: DC 7/21/03 #21663  - Add HQMA audit to these tables.
    * Modified: EN 02/18/03 - issue 23061  added with (nolock), and dbo
	*			EN 7/09/08  #127015  added HQMA auditing for MiscFedDL1, MiscFedDL2, MiscFedDL3, and MiscFedDL4
    *
    *	
    *
    *	
    */----------------------------------------------------------------
    
   declare @numrows int
    
   select @numrows = @@rowcount
   if @numrows = 0 return
    
   set nocount on
   
   -- add HQ Master Audit entry   DC #21663
   IF exists (select top 1 1 from inserted i join dbo.bPRCO a with (nolock) on a.PRCo = i.PRCo where a.AuditTaxes = 'Y')
     	begin
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRFI',  'PRCo: ' + convert(char(2), i.PRCo), i.PRCo, 'C','TaxDedn',
   		d.TaxDedn,i.TaxDedn,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo 
          	where isnull(i.TaxDedn,'') <> isnull(d.TaxDedn,'')
     
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRFI',  'PRCo: ' + convert(char(2), i.PRCo), i.PRCo, 'C','FUTALiab',
   		d.FUTALiab,i.FUTALiab,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo
          	where isnull(i.FUTALiab,'') <> isnull(d.FUTALiab,'')
     
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRFI',  'PRCo: ' + convert(char(2), i.PRCo), i.PRCo, 'C','MiscFedDL1',
   		d.MiscFedDL1,i.MiscFedDL1,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo
          	where isnull(i.MiscFedDL1,'') <> isnull(d.MiscFedDL1,'')
     
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRFI',  'PRCo: ' + convert(char(2), i.PRCo), i.PRCo, 'C','MiscFedDL2',
   		d.MiscFedDL2,i.MiscFedDL2,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo
          	where isnull(i.MiscFedDL2,'') <> isnull(d.MiscFedDL2,'')
     
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRFI',  'PRCo: ' + convert(char(2), i.PRCo), i.PRCo, 'C','MiscFedDL3',
   		d.MiscFedDL3,i.MiscFedDL3,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo
          	where isnull(i.MiscFedDL3,'') <> isnull(d.MiscFedDL3,'')
     
   	insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bPRFI',  'PRCo: ' + convert(char(2), i.PRCo), i.PRCo, 'C','MiscFedDL4',
   		d.MiscFedDL4,i.MiscFedDL4,getdate(), SUSER_SNAME()
   	from inserted i
           join deleted d on i.PRCo = d.PRCo
          	where isnull(i.MiscFedDL4,'') <> isnull(d.MiscFedDL4,'')
   	END
   
   return
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_bPRFI_KeyID] ON [dbo].[bPRFI] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_bPRFI_PRCo] ON [dbo].[bPRFI] ([PRCo]) ON [PRIMARY]
GO
