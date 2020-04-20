CREATE TABLE [dbo].[bAPVH]
(
[APCo] [dbo].[bCompany] NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[HoldCode] [dbo].[bHoldCode] NOT NULL,
[Memo] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btAPVHd    Script Date: 8/28/99 9:37:00 AM ******/
   CREATE  trigger [dbo].[btAPVHd] on [dbo].[bAPVH] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created: EN 8/3/98
    *  Modified: EN 8/3/98
    *			MV 10/18/02 - 18878 quoted identifier cleanup
    *
    * Validates and inserts HQ Master Audit entry.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   select @numrows = @@rowcount
   set nocount on
   if @numrows = 0 return
   /* Audit AP Vendor Hold Code deletions */
   INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
           SELECT 'bAPVH','Vendor Group: ' + convert(char(3),d.VendorGroup)
            + 'Vendor: ' + convert(varchar(6),d.Vendor)
            + 'Hold Code:' + convert (varchar(3),d.HoldCode),
             d.APCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
           FROM deleted d
   	JOIN bAPCO c ON d.APCo=c.APCo
           where c.AuditHold = 'Y'
   return
   error:
   	select @errmsg = @errmsg + ' - cannot delete AP Vendor Hold Code!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btAPVHi    Script Date: 8/28/99 9:37:00 AM ******/
   CREATE trigger [dbo].[btAPVHi] on [dbo].[bAPVH] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created: EN 8/3/98
    *  Modified: EN 8/3/98
	*				MV 9/8/8 - #129741 don't set no count on before numrows check
    *
    * Validates AP Co#, VendorGroup, Vendor and HoldCode.
    * If Hold Codes flagged for auditing, inserts HQ Master Audit entry .
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @validcnt int, @numrows int
   --set nocount on
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
   /* validate HoldCode */
   SELECT @validcnt = count(*) FROM bHQHC h
   	JOIN inserted i ON i.HoldCode = h.HoldCode
   IF @validcnt <> @numrows
   	BEGIN
   	SELECT @errmsg = 'Invalid Hold Code'
   	GOTO error
   	END
   /* Audit inserts */
   INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bAPVH',' Vendor Group: ' + convert(char(3), i.VendorGroup)
   		 + ' Vendor: ' + convert(varchar(6), i.Vendor)
   		 + ' Hold Code: ' + convert(varchar(3),i.HoldCode), i.APCo, 'A',
   		NULL, NULL, NULL, getdate(), SUSER_SNAME() FROM inserted i
   		join bAPCO c on c.APCo = i.APCo
   		where c.APCo = i.APCo and c.AuditHold = 'Y'
   return
   error:
       SELECT @errmsg = @errmsg +  ' - cannot insert AP Vendor Hold Code!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btAPVHu    Script Date: 8/28/99 9:37:00 AM ******/
   CREATE  trigger [dbo].[btAPVHu] on [dbo].[bAPVH] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created: EN 8/3/98
    *  Modified: EN 8/3/98
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
       	and d.HoldCode = i.HoldCode
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Cannot change AP Company, Vendor Group, Vendor or Hold Code'
   	goto error
   	end
   
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot update Vendor Hold Code!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biAPVH] ON [dbo].[bAPVH] ([APCo], [VendorGroup], [Vendor], [HoldCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bAPVH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
