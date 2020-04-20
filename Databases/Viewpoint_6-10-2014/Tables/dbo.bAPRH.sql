CREATE TABLE [dbo].[bAPRH]
(
[APCo] [dbo].[bCompany] NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[InvId] [char] (10) COLLATE Latin1_General_BIN NULL,
[Description] [dbo].[bDesc] NULL,
[PayTerms] [dbo].[bDesc] NULL,
[HoldCode] [dbo].[bHoldCode] NULL,
[Frequency] [dbo].[bFreq] NOT NULL,
[MnthlyYN] [dbo].[bYN] NOT NULL,
[InvDay] [tinyint] NULL,
[PayControl] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[PayMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[CMCo] [dbo].[bCompany] NOT NULL,
[CMAcct] [dbo].[bCMAcct] NULL,
[V1099YN] [dbo].[bYN] NOT NULL,
[V1099Type] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[V1099Box] [tinyint] NULL,
[LastMth] [dbo].[bMonth] NULL,
[LastSeq] [smallint] NOT NULL,
[InvToDate] [dbo].[bDollar] NOT NULL,
[ExpDate] [dbo].[bDate] NULL,
[InvLimit] [dbo].[bDollar] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[AddressSeq] [tinyint] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[udFreightCost] [dbo].[bDollar] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btAPRHd    Script Date: 8/28/99 9:36:56 AM ******/
   CREATE  trigger [dbo].[btAPRHd] on [dbo].[bAPRH] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created: EN 11/2/98
    *  Modified: EN 11/2/98
    *			MV 10/17/02 - 18878 quoted identifier cleanup.
	*			MV 06/01/09 - #133431 - delete attachments per issue #127603 
    *
    *  This trigger restricts deletion if detail exists in APRL.
    *  Adds entry to HQ Master Audit if APCO.AuditRecur = 'Y'.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   if exists(select * from bAPRL a, deleted d where a.APCo=d.APCo and a.VendorGroup=d.VendorGroup
   	and a.Vendor=d.Vendor and a.InvId=d.InvId)
   	begin
   	select @errmsg='Lines exist for this header'
   	goto error
   	end

	-- delete attachments
	insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
          select AttachmentID, suser_name(), 'Y' 
              from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID                  
              where d.UniqueAttchID is not null    

   /* Audit AP Recurring Invoice Header deletions */
   INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
           SELECT 'bAPRH',' VendorGroup: ' + convert(varchar(3),d.VendorGroup)
   		 + ' Vendor: ' + convert(varchar(6),d.Vendor)
   		 + ' InvId: ' + d.InvId, d.APCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
           FROM deleted d
   	JOIN bAPCO c ON d.APCo = c.APCo
           where c.AuditRecur = 'Y'
   return
   error:
   	select @errmsg = @errmsg + ' - cannot delete AP Recurring Invoice Header!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btAPRHi    Script Date: 8/28/99 9:36:56 AM ******/
   CREATE trigger [dbo].[btAPRHi] on [dbo].[bAPRH] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created: EN 10/29/98
    *  Modified: EN 10/29/98
    *            CMW 04/03/02 - increased InvId from 5 to 10 char (issue # 16366)
    *
    * Validates APCo, and Vendor.
    * If flagged for auditing recurring invoices, inserts HQ Master Audit entry.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @validcnt int, @numrows int
   set nocount on
   SELECT @numrows = @@rowcount
   IF @numrows = 0 return
   SET nocount on
   /* validate AP Company */
   SELECT @validcnt = count(*) FROM bAPCO c
   	JOIN inserted i ON c.APCo = i.APCo
   IF @validcnt <> @numrows
   	BEGIN
   	SELECT @errmsg = 'Invalid AP Company'
   	GOTO error
   	END
   /* validate Vendor */
   SELECT @validcnt = count(*) FROM bAPVM v
   	JOIN inserted i ON v.VendorGroup = i.VendorGroup and v.Vendor = i.Vendor
   IF @validcnt <> @numrows
   	BEGIN
   	SELECT @errmsg = 'Invalid Vendor'
   	GOTO error
   	END
   /* Audit inserts */
   INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bAPRH',' VendorGroup: ' + convert(char(3), i.VendorGroup)
   		 + ' Vendor: ' + convert(varchar(6), i.Vendor)
   		 + ' InvId: ' + convert(char(10),i.InvId), i.APCo, 'A',
   		NULL, NULL, NULL, getdate(), SUSER_SNAME() FROM inserted i
   		join bAPCO c on c.APCo = i.APCo
   		where i.APCo = c.APCo and c.AuditRecur = 'Y'
   return
   error:
       SELECT @errmsg = @errmsg +  ' - cannot insert AP Recurring Invoice Header!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btAPRHu    Script Date: 8/28/99 9:36:56 AM ******/
   CREATE trigger [dbo].[btAPRHu] on [dbo].[bAPRH] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created: EN 11/2/98
    *  Modified: EN 11/2/98
    *			MV 10/17/02 - 18878 quoted identifier cleanup. 
    *			MV 03/19/03 - 17124 - added AddressSeq to HQMA audit.
    *			GF 08/12/2003 - issue #22112 - performance
    *
    * Reject primary key changes.
    * If Recurring invoices flagged for auditing, inserts HQ Master Audit entries
    *	for changed value.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- check for key changes
   select @validcnt = count(*) from deleted d
   join inserted i on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup 
   and d.Vendor = i.Vendor and d.InvId = i.InvId
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Cannot change key information.'
   	goto error
   	end
   
   
   -- Check bAPCO to see if auditing recurring. If not done.
   if not exists(select top 1 1 from inserted i join bAPCO c with (nolock) on i.APCo=c.APCo where c.AuditRecur = 'Y')
   	return
   
   
   -- Insert records into HQMA for changes made to audited fields
   if update(Description)
   BEGIN
   	insert into bHQMA select 'bAPRH', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   	+ ' Vendor: ' + convert(varchar(6), i.Vendor) + ' InvId: ' + i.InvId, i.APCo, 'C',
   	'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId
   	join bAPCO a with (nolock) on a.APCo = i.APCo
   	where d.Description <> i.Description and a.AuditRecur = 'Y'
   END
   
   if update(PayTerms)
   BEGIN
   	insert into bHQMA select 'bAPRH', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   	+ ' Vendor: ' + convert(varchar(6), i.Vendor) + ' InvId: ' + i.InvId, i.APCo, 'C',
   	'PayTerms', d.PayTerms, i.PayTerms, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId
   	join bAPCO a with (nolock) on a.APCo = i.APCo
   	where d.PayTerms <> i.PayTerms and a.AuditRecur = 'Y'
   END
   
   if update(HoldCode)
   BEGIN
   	insert into bHQMA select 'bAPRH', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   	+ ' Vendor: ' + convert(varchar(6), i.Vendor) + ' InvId: ' + i.InvId, i.APCo, 'C',
   	'HoldCode', d.HoldCode, i.HoldCode, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId
   	join bAPCO a with (nolock) on a.APCo = i.APCo
   	where d.HoldCode <> i.HoldCode and a.AuditRecur = 'Y'
   END
   
   if update(Frequency)
   BEGIN
   	insert into bHQMA select 'bAPRH', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   	+ ' Vendor: ' + convert(varchar(6), i.Vendor) + ' InvId: ' + i.InvId, i.APCo, 'C',
   	'Frequency', d.Frequency, i.Frequency, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId
   	join bAPCO a with (nolock) on a.APCo = i.APCo
   	where d.Frequency <> i.Frequency and a.AuditRecur = 'Y'
   END
   
   if update(MnthlyYN)
   BEGIN
   	insert into bHQMA select 'bAPRH', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   	+ ' Vendor: ' + convert(varchar(6), i.Vendor) + ' InvId: ' + i.InvId, i.APCo, 'C',
   	'MnthlyYN', d.MnthlyYN, i.MnthlyYN, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId
   	join bAPCO a with (nolock) on a.APCo = i.APCo
   	where d.MnthlyYN <> i.MnthlyYN and a.AuditRecur = 'Y'
   END
   
   if update(InvDay)
   BEGIN
   	insert into bHQMA select 'bAPRH', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   	+ ' Vendor: ' + convert(varchar(6), i.Vendor) + ' InvId: ' + i.InvId, i.APCo, 'C',
   	'InvDay', convert(varchar(3),d.InvDay), convert(varchar(3),i.InvDay), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId
   	join bAPCO a with (nolock) on a.APCo = i.APCo
   	where d.InvDay <> i.InvDay and a.AuditRecur = 'Y'
   END
   
   if update(PayControl)
   BEGIN
   	insert into bHQMA select 'bAPRH', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   	+ ' Vendor: ' + convert(varchar(6), i.Vendor) + ' InvId: ' + i.InvId, i.APCo, 'C',
   	'PayControl', d.PayControl, i.PayControl, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId
   	join bAPCO a with (nolock) on a.APCo = i.APCo
   	where d.PayControl <> i.PayControl and a.AuditRecur = 'Y'
   END
   
   if update(PayMethod)
   BEGIN
   	insert into bHQMA select 'bAPRH', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   	+ ' Vendor: ' + convert(varchar(6), i.Vendor) + ' InvId: ' + i.InvId, i.APCo, 'C',
   	'PayMethod', d.PayMethod, i.PayMethod, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId
   	join bAPCO a with (nolock) on a.APCo = i.APCo
   	where d.PayMethod <> i.PayMethod and a.AuditRecur = 'Y'
   END
   
   if update(CMCo)
   BEGIN
   	insert into bHQMA select 'bAPRH', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   	+ ' Vendor: ' + convert(varchar(6), i.Vendor) + ' InvId: ' + i.InvId, i.APCo, 'C',
   	'CMCo', convert(varchar(3),d.CMCo), convert(varchar(3),i.CMCo), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId
   	join bAPCO a with (nolock) on a.APCo = i.APCo
   	where d.CMCo <> i.CMCo and a.AuditRecur = 'Y'
   END
   
   if update(CMAcct)
   BEGIN
   	insert into bHQMA select 'bAPRH', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   	+ ' Vendor: ' + convert(varchar(6), i.Vendor) + ' InvId: ' + i.InvId, i.APCo, 'C',
   	'CMAcct', convert(varchar(5),d.CMAcct), convert(varchar(5),i.CMAcct), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId
   	join bAPCO a with (nolock) on a.APCo = i.APCo
   	where d.CMAcct <> i.CMAcct and a.AuditRecur = 'Y'
   END
   
   if update(V1099YN)
   BEGIN
   	insert into bHQMA select 'bAPRH', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   	+ ' Vendor: ' + convert(varchar(6), i.Vendor) + ' InvId: ' + i.InvId, i.APCo, 'C',
   	'V1099YN', d.V1099YN, i.V1099YN, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId
   	join bAPCO a with (nolock) on a.APCo = i.APCo
   	where d.V1099YN <> i.V1099YN and a.AuditRecur = 'Y'
   END
   
   if update(V1099Type)
   BEGIN
   	insert into bHQMA select 'bAPRH', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   	+ ' Vendor: ' + convert(varchar(6), i.Vendor) + ' InvId: ' + i.InvId, i.APCo, 'C',
   	'V1099Type', d.V1099Type, i.V1099Type, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId
   	join bAPCO a with (nolock) on a.APCo = i.APCo
   	where d.V1099Type <> i.V1099Type and a.AuditRecur = 'Y'
   END
   
   if update(V1099Box)
   BEGIN
   	insert into bHQMA select 'bAPRH', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   	+ ' Vendor: ' + convert(varchar(6), i.Vendor) + ' InvId: ' + i.InvId, i.APCo, 'C',
   	'V1099Box', convert(varchar(3),d.V1099Box), convert(varchar(3),i.V1099Box), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId
   	join bAPCO a with (nolock) on a.APCo = i.APCo
   	where d.V1099Box <> i.V1099Box and a.AuditRecur = 'Y'
   END
   
   if update(LastMth)
   BEGIN
   	insert into bHQMA select 'bAPRH', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   	+ ' Vendor: ' + convert(varchar(6), i.Vendor) + ' InvId: ' + i.InvId, i.APCo, 'C',
   	'LastMth', convert(varchar(8),d.LastMth), convert(varchar(8),i.LastMth), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId
   	join bAPCO a with (nolock) on a.APCo = i.APCo
   	where d.LastMth <> i.LastMth and a.AuditRecur = 'Y'
   END
   
   if update(LastSeq)
   BEGIN
   	insert into bHQMA select 'bAPRH', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   	+ ' Vendor: ' + convert(varchar(6), i.Vendor) + ' InvId: ' + i.InvId, i.APCo, 'C',
   	'LastSeq', convert(varchar(5),d.LastSeq), convert(varchar(5),i.LastSeq), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId
   	join bAPCO a with (nolock) on a.APCo = i.APCo
   	where d.LastSeq <> i.LastSeq and a.AuditRecur = 'Y'
   END
   
   if update(InvToDate)
   BEGIN
   	insert into bHQMA select 'bAPRH', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   	+ ' Vendor: ' + convert(varchar(6), i.Vendor) + ' InvId: ' + i.InvId, i.APCo, 'C',
   	'InvToDate', convert(varchar(16),d.InvToDate), convert(varchar(16),i.InvToDate), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId
   	join bAPCO a with (nolock) on a.APCo = i.APCo
   	where d.InvToDate <> i.InvToDate and a.AuditRecur = 'Y'
   END
   
   if update(ExpDate)
   BEGIN
   	insert into bHQMA select 'bAPRH', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   	+ ' Vendor: ' + convert(varchar(6), i.Vendor) + ' InvId: ' + i.InvId, i.APCo, 'C',
   	'ExpDate', convert(varchar(8),d.ExpDate), convert(varchar(8),i.ExpDate), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId
   	join bAPCO a with (nolock) on a.APCo = i.APCo
   	where d.ExpDate <> i.ExpDate and a.AuditRecur = 'Y'
   END
   
   if update(InvLimit)
   BEGIN
   	insert into bHQMA select 'bAPRH', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   	+ ' Vendor: ' + convert(varchar(6), i.Vendor) + ' InvId: ' + i.InvId, i.APCo, 'C',
   	'InvLimit', convert(varchar(16),d.InvLimit), convert(varchar(16),i.InvLimit), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId
   	join bAPCO a with (nolock) on a.APCo = i.APCo
   	where d.InvLimit <> i.InvLimit and a.AuditRecur = 'Y'
   END
   
   if update(AddressSeq)
   BEGIN
   	insert into bHQMA select 'bAPRH', ' VendorGroup: ' + convert(char(5), i.VendorGroup)
   	+ ' Vendor: ' + convert(varchar(6), i.Vendor) + ' InvId: ' + i.InvId, i.APCo, 'C',
   	'Addtl Address Seq #', convert(varchar(16),d.AddressSeq), convert(varchar(16),i.AddressSeq), getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on d.APCo = i.APCo and d.VendorGroup = i.VendorGroup
   	and d.Vendor = i.Vendor and d.InvId = i.InvId
   	join bAPCO a with (nolock) on a.APCo = i.APCo
   	where d.AddressSeq <> i.AddressSeq and a.AuditRecur = 'Y'
   END
   
   
   return
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot update Recurring Invoice Header!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
ALTER TABLE [dbo].[bAPRH] WITH NOCHECK ADD CONSTRAINT [CK_bAPRH_CMAcct] CHECK (([CMAcct]>(0) AND [CMAcct]<(10000) OR [CMAcct] IS NULL))
GO
ALTER TABLE [dbo].[bAPRH] WITH NOCHECK ADD CONSTRAINT [CK_bAPRH_MnthlyYN] CHECK (([MnthlyYN]='Y' OR [MnthlyYN]='N'))
GO
ALTER TABLE [dbo].[bAPRH] WITH NOCHECK ADD CONSTRAINT [CK_bAPRH_V1099YN] CHECK (([V1099YN]='Y' OR [V1099YN]='N'))
GO
CREATE UNIQUE CLUSTERED INDEX [biAPRH] ON [dbo].[bAPRH] ([APCo], [VendorGroup], [Vendor], [InvId]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bAPRH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biAPRHUniqueAttId] ON [dbo].[bAPRH] ([UniqueAttchID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
