CREATE TABLE [dbo].[bAPVC]
(
[APCo] [dbo].[bCompany] NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[CompCode] [dbo].[bCompCode] NOT NULL,
[Verify] [dbo].[bYN] NOT NULL,
[ExpDate] [dbo].[bDate] NULL,
[Complied] [dbo].[bYN] NULL,
[Memo] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btAPVCd    Script Date: 8/28/99 9:36:59 AM ******/
   CREATE  trigger [dbo].[btAPVCd] on [dbo].[bAPVC] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created: EN 8/10/98
    *  Modified: EN 8/10/98
    *			MV 10/18/02 - 18878 quoted identifier cleanup
    *
    * Adds entry to HQ Master Audit if APCO.AuditComp = 'Y'.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   select @numrows = @@rowcount
   set nocount on
   if @numrows = 0 return
   /* Audit AP Vendor Compliance Code deletions */
   INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
           SELECT 'bAPVC','Vendor Group: ' + convert(char(3),d.VendorGroup)
            + 'Vendor: ' + convert(varchar(6),d.Vendor)
            + 'Comp Code:' + convert (varchar(3),d.CompCode),
             d.APCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
           FROM deleted d
   	JOIN bAPCO c ON d.APCo=c.APCo
           where c.AuditComp = 'Y'
   return
   error:
   	select @errmsg = @errmsg + ' - cannot delete AP Vendor Compliance Code!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btAPVCi    Script Date: 8/28/99 9:37:00 AM ******/
   CREATE trigger [dbo].[btAPVCi] on [dbo].[bAPVC] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created: EN 8/3/98
    *  Modified: EN 8/3/98
    *
    * Validates AP Co#, VendorGroup, Vendor and HoldCode.
    * If Hold Codes flagged for auditing, inserts HQ Master Audit entry .
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @validcnt int, @numrows int
   set nocount ON
   SELECT @numrows = @@rowcount
   IF @numrows = 0 return
   SET nocount on
   /* validate AP Co# */
   SELECT @validcnt = count(*) FROM inserted i
   	JOIN bAPCO c ON c.APCo = i.APCo
   IF @validcnt <> @numrows
   	BEGIN
   	SELECT @errmsg = 'Invalid AP company'
   	GOTO error
   	END
   /* validate VendorGroup */
   SELECT @validcnt = count(*) FROM bHQCO c
          JOIN inserted i ON i.APCo = c.HQCo and i.VendorGroup = c.VendorGroup
   IF @validcnt <> @numrows
   	BEGIN
   	SELECT @errmsg = 'Invalid Vendor Group'
   	GOTO error
   	END
   /* validate Vendor */
   SELECT @validcnt = count(*) FROM bAPVM v
   	JOIN inserted i ON i.VendorGroup = v.VendorGroup and i.Vendor = v.Vendor
   IF @validcnt <> @numrows
   	BEGIN
   	SELECT @errmsg = 'Invalid Vendor'
   	GOTO error
   	END
   /* validate CompCode */
   SELECT @validcnt = count(*) FROM bHQCP c
   	JOIN inserted i ON i.CompCode = c.CompCode
   IF @validcnt <> @numrows
   	BEGIN
   	SELECT @errmsg = 'Invalid Compliance Code'
   	GOTO error
   	END
   /* Audit inserts */
   INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bAPVC',' Vendor Group: ' + convert(char(3), i.VendorGroup)
   		 + ' Vendor: ' + convert(varchar(6), i.Vendor)
   		 + ' Comp Code: ' + convert(varchar(10),i.CompCode), i.APCo, 'A',
   		NULL, NULL, NULL, getdate(), SUSER_SNAME() FROM inserted i
   		join bAPCO c on c.APCo = i.APCo
   		where i.APCo = c.APCo and c.AuditComp = 'Y'
   return
   error:
       SELECT @errmsg = @errmsg +  ' - cannot insert AP Vendor Compliance Code!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btAPVCu    Script Date: 8/28/99 9:37:00 AM ******/
   CREATE  trigger [dbo].[btAPVCu] on [dbo].[bAPVC] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created: EN 8/3/98
    *  Modified: EN 8/11/98
    *			MV 10/18/02 - 18878 quoted identifier cleanup. 
    *
    * Cannot change primary key - APCo, VendorGroup, Vendor and HoldCode
    * If Hold Codes flagged for auditing, inserts HQ Master Audit entries.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   /* check for key changes */
   select @validcnt = count(*) from deleted d
       join inserted i on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup and d.Vendor = i.Vendor
       	and d.CompCode = i.CompCode
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Cannot change AP Company, Vendor Group, Vendor or Compliance Code'
   	goto error
   	end
   /* Insert records into HQMA for changes made to audited fields */
   insert into bHQMA select 'bAPVC', 'VendorGroup: ' + convert(char(3),i.VendorGroup)
   	+ 'Vendor: ' + convert(varchar(6),i.Vendor)
   	+ 'Comp Code: ' + convert(varchar(10),i.CompCode), i.APCo, 'C',
   	'Verify', d.Verify, i.Verify, getdate(), SUSER_SNAME()
   	from inserted i
       join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
       	and d.Vendor = i.Vendor and d.CompCode = i.CompCode
       join APCO a on a.APCo = i.APCo
   	where d.Verify <> i.Verify and a.AuditComp = 'Y'
   insert into bHQMA select 'bAPVC', 'VendorGroup: ' + convert(char(3),i.VendorGroup)
   	+ 'Vendor: ' + convert(varchar(6),i.Vendor)
   	+ 'Comp Code: ' + convert(varchar(10),i.CompCode), i.APCo, 'C',
   	'ExpDate', d.ExpDate, i.ExpDate, getdate(), SUSER_SNAME()
   	from inserted i
       join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
       	and d.Vendor = i.Vendor and d.CompCode = i.CompCode
       join APCO a on a.APCo = i.APCo
   	where d.ExpDate <> i.ExpDate and a.AuditComp = 'Y'
   insert into bHQMA select 'bAPVC', 'VendorGroup: ' + convert(char(3),i.VendorGroup)
   	+ 'Vendor: ' + convert(varchar(6),i.Vendor)
   	+ 'Comp Code: ' + convert(varchar(10),i.CompCode), i.APCo, 'C',
   	'Complied', d.Complied, i.Complied, getdate(), SUSER_SNAME()
   	from inserted i
       join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
       	and d.Vendor = i.Vendor and d.CompCode = i.CompCode
       join APCO a on a.APCo = i.APCo
   	where d.Complied <> i.Complied and a.AuditComp = 'Y'
   return
   error:
   	select @errmsg = @errmsg + ' - cannot update Vendor Compliance Code!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biAPVC] ON [dbo].[bAPVC] ([APCo], [VendorGroup], [Vendor], [CompCode]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bAPVC] ([KeyID]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPVC].[Verify]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPVC].[Complied]'
GO
