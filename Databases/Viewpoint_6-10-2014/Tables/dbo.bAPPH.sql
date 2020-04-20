CREATE TABLE [dbo].[bAPPH]
(
[APCo] [dbo].[bCompany] NOT NULL,
[CMCo] [dbo].[bCompany] NOT NULL,
[CMAcct] [dbo].[bCMAcct] NOT NULL,
[PayMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[CMRef] [dbo].[bCMRef] NOT NULL,
[CMRefSeq] [tinyint] NOT NULL,
[EFTSeq] [smallint] NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[Name] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Address] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Zip] [dbo].[bZip] NULL,
[ChkType] [char] (1) COLLATE Latin1_General_BIN NULL,
[PaidMth] [dbo].[bMonth] NOT NULL,
[PaidDate] [dbo].[bDate] NOT NULL,
[Amount] [dbo].[bDollar] NOT NULL,
[Supplier] [dbo].[bVendor] NULL,
[VoidYN] [dbo].[bYN] NOT NULL,
[VoidMemo] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[InUseMth] [dbo].[bMonth] NULL,
[InUseBatchId] [dbo].[bBatchID] NULL,
[PurgeYN] [dbo].[bYN] NOT NULL,
[BatchId] [dbo].[bBatchID] NULL,
[AddnlInfo] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Country] [char] (2) COLLATE Latin1_General_BIN NULL,
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  trigger [dbo].[btAPPHd] on [dbo].[bAPPH] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created: EN 9/12/98
    *  Modified: kb 11/4/98
    *			MV 10/17/02 - 18878 quoted identifier cleanup. 
    *
    * Reject if bAPPD entries exist.
    * Adds entry to HQ Master Audit if APCO.AuditPay = 'Y' and
    *	APPH.PurgeYN = 'N'.
    */----------------------------------------------------------------
   
   declare @errmsg varchar(255), @numrows int
   
   select @numrows = @@rowcount
   set nocount on
   
   if @numrows = 0 return
   
   /* check AP Payment Detail */
   if exists(select * from bAPPD p, deleted d where p.APCo = d.APCo and p.CMCo = d.CMCo
   	  and p.CMAcct = d.CMAcct and p.PayMethod = d.PayMethod and p.CMRef = d.CMRef
   	  and p.CMRefSeq = d.CMRefSeq and p.EFTSeq = d.EFTSeq)
   	begin
   	 select @errmsg = 'Entries exist in AP Payment Detail for this entry'
   	 goto error
   	end
   	
   INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
           SELECT 'bAPPH',' Key: ' + convert(varchar(3), d.CMCo)
   		 + '/' + convert(varchar(4), d.CMAcct)
   		 + '/' + convert(varchar(1),d.PayMethod)
   		 + '/' + convert(varchar(10),d.CMRef)
   		 + '/' + convert(varchar(1),d.CMRefSeq)
   		 + '/' + convert(varchar(4),d.EFTSeq),
             d.APCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
           FROM deleted d
   	JOIN bAPCO c ON d.APCo = c.APCo
           where c.AuditPay = 'Y' and d.PurgeYN = 'N'
   
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete AP Payment Header!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[btAPPHi] on [dbo].[bAPPH] for INSERT as

/*-----------------------------------------------------------------
*  Created: EN 09/11/98
*  Modified: kb 11/4/98
*			 EN 4/21/12 - TK-13962 Modified to allow Pay Method 'S' and to remove 'set nocount on' from before
*							'select @numrows = @@rowcount' which clears value of @@rowcount and therefore @numrows
*							get set to 0 which causes immediate exit of trigger without running it
*			 KK 4/23/12 - B-08111 Modified the Supplier validation to compare the inserted vendor with vendor if supplier is null
*
* Validates APCo, CMCo, CMAcct, PayMethod, Vendor, and Supplier.
* If flagged for auditing pay history, inserts HQ Master Audit entry.
*/----------------------------------------------------------------
   
DECLARE @errmsg varchar(255), @validcnt int, @numrows int

SELECT @numrows = @@ROWCOUNT
IF @numrows = 0 RETURN
SET NOCOUNT ON

/* validate AP Company */
SELECT @validcnt = count(*) FROM bAPCO c
JOIN inserted i ON c.APCo = i.APCo
IF @validcnt <> @numrows
BEGIN
	SELECT @errmsg = 'Invalid AP Company'
	GOTO error
END

/* validate CM Company */
SELECT @validcnt = count(*) FROM bCMCO c
JOIN inserted i ON c.CMCo = i.CMCo
IF @validcnt <> @numrows
BEGIN
	SELECT @errmsg = 'Invalid CM Company'
	GOTO error
END

/* validate CM Account */
SELECT @validcnt = count(*) FROM bCMAC a
JOIN inserted i ON a.CMCo = i.CMCo and a.CMAcct = i.CMAcct
IF @validcnt <> @numrows
BEGIN
	SELECT @errmsg = 'Invalid CM Account'
	GOTO error
END

/* validate Pay Method */
SELECT @validcnt = count(*) FROM inserted WHERE PayMethod NOT IN ('C','E','S')
IF @validcnt > 0
BEGIN
   SELECT @errmsg = 'Payment Method must be C, E or S.'
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

/* validate Supplier */
SELECT @validcnt = count(*) FROM bAPVM v
JOIN inserted i ON v.VendorGroup = i.VendorGroup and v.Vendor = isnull(i.Supplier, i.Vendor)
IF @validcnt <> @numrows
BEGIN
	SELECT @errmsg = 'Invalid Supplier'
	GOTO error
END

/* Audit inserts */
INSERT INTO bHQMA
   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 'bAPPH',' Key: ' + convert(varchar(3), i.CMCo)
	 + '/' + convert(varchar(10), i.CMAcct)
	 + '/' + convert(char(1),i.PayMethod)
	 + '/' + convert(varchar(10),i.CMRef)
	 + '/' + convert(varchar(3),i.CMRefSeq)
	 + '/' + convert(varchar(4),i.EFTSeq), i.APCo, 'A',
	NULL, NULL, NULL, getdate(), SUSER_SNAME() FROM inserted i
	join bAPCO c on c.APCo = i.APCo
	where i.APCo = c.APCo and c.AuditPay = 'Y'
	

return

error:
   SELECT @errmsg = @errmsg +  ' - cannot insert AP Payment Header!'
   RAISERROR(@errmsg, 11, -1);
   rollback transaction

   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  trigger [dbo].[btAPPHu] on [dbo].[bAPPH] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created: EN 9/11/98
    *  Modified: kb 10/30/98
    *            EN 1/22/00 - insert bHQMA if AddnlInfo is changed
    *			MV 10/17/02 - 18878 quoted identifier cleanup. 
    *
    * Cannot change primary key - APCo, CMCo, CMAcct, PayMethod,
    *	CMRef, CMRefSeq, EFTSeq
    * Validate Vendor and Supplier if changed.
    * If Pay History flagged for auditing, inserts HQ Master Audit entries
    *	for changed value.
    */----------------------------------------------------------------
   
   declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* check for key changes */
   select @validcnt = count(*) from deleted d
       join inserted i on d.APCo = i.APCo and d.CMCo = i.CMCo and d.CMAcct = i.CMAcct
       	and d.PayMethod = i.PayMethod and d.CMRef = i.CMRef and d.CMRefSeq = i.CMRefSeq
       	and d.EFTSeq = i.EFTSeq
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Cannot change key information.'
   	goto error
   	end
   
   /* validate Vendor */
   if update (Vendor) or update(VendorGroup)
   	begin
   	select @validcnt = count(*) from inserted i
   	    	join APVM v on v.VendorGroup = i.VendorGroup and v.Vendor = i.Vendor
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid Vendor ' + convert(varchar(10),@validcnt) + ' - ' + convert(varchar(10),@numrows)
   		goto error
   		end
   	end
   
   /* validate Supplier */
   if update (VendorGroup) or update(Supplier)
   	begin
   	select @validcnt = count(*) from inserted i
   		join APVM v on v.VendorGroup = i.VendorGroup and v.Vendor = isnull(i.Supplier, v.Vendor)
   	IF @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid Supplier'
   		goto error
   		end
   	end
   
    /* Insert records into HQMA for changes made to audited fields */
    insert into bHQMA select 'bAPPH', 'Key: ' + convert(char(3), i.CMCo)
    		 + '/' + convert(varchar(4), i.CMAcct)
    		 + '/' + i.PayMethod
    		 + '/' + i.CMRef
    		 + '/' + convert(varchar(1),i.CMRefSeq)
    		 + '/' + convert(varchar(4),i.EFTSeq), i.APCo, 'C',
    	'VendorGroup', convert(varchar(5),d.VendorGroup), convert(varchar(5),i.VendorGroup), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.CMCo = i.CMCo and d.CMAcct = i.CMAcct
        	and d.PayMethod = i.PayMethod and d.CMRef = i.CMRef and d.CMRefSeq = i.CMRefSeq
        	and d.EFTSeq = i.EFTSeq
   
        join APCO a on a.APCo = i.APCo
    	where d.VendorGroup <> i.VendorGroup and a.AuditPay = 'Y'
   
    insert into bHQMA select 'bAPPH', 'Key: ' + convert(char(3), i.CMCo)
    		 + '/' + convert(varchar(4), i.CMAcct)
    		 + '/' + i.PayMethod
    		 + '/' + i.CMRef
    		 + '/' + convert(varchar(1),i.CMRefSeq)
    		 + '/' + convert(varchar(4),i.EFTSeq), i.APCo, 'C',
    	'Vendor', convert(varchar(6),d.Vendor), convert(varchar(6),i.Vendor), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.CMCo = i.CMCo and d.CMAcct = i.CMAcct
        	and d.PayMethod = i.PayMethod and d.CMRef = i.CMRef and d.CMRefSeq = i.CMRefSeq
        	and d.EFTSeq = i.EFTSeq
        join APCO a on a.APCo = i.APCo
    	where d.Vendor <> i.Vendor and a.AuditPay = 'Y'
   
    insert into bHQMA select 'bAPPH', 'Key: ' + convert(char(3), i.CMCo)
    		 + '/' + convert(varchar(4), i.CMAcct)
    		 + '/' + i.PayMethod
    		 + '/' + i.CMRef
    		 + '/' + convert(varchar(1),i.CMRefSeq)
    		 + '/' + convert(varchar(4),i.EFTSeq), i.APCo, 'C',
    	'Name', d.Name, i.Name, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.CMCo = i.CMCo and d.CMAcct = i.CMAcct
        	and d.PayMethod = i.PayMethod and d.CMRef = i.CMRef and d.CMRefSeq = i.CMRefSeq
        	and d.EFTSeq = i.EFTSeq
        join APCO a on a.APCo = i.APCo
    	where d.Name <> i.Name and a.AuditPay = 'Y'
   
    insert into bHQMA select 'bAPPH', 'Key: ' + convert(char(3), i.CMCo)
    		 + '/' + convert(varchar(4), i.CMAcct)
    		 + '/' + i.PayMethod
    		 + '/' + i.CMRef
    		 + '/' + convert(varchar(1),i.CMRefSeq)
    		 + '/' + convert(varchar(4),i.EFTSeq), i.APCo, 'C',
    	'AddnlInfo', d.AddnlInfo, i.AddnlInfo, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.CMCo = i.CMCo and d.CMAcct = i.CMAcct
        	and d.PayMethod = i.PayMethod and d.CMRef = i.CMRef and d.CMRefSeq = i.CMRefSeq
        	and d.EFTSeq = i.EFTSeq
        join APCO a on a.APCo = i.APCo
    	where d.AddnlInfo <> i.AddnlInfo and a.AuditPay = 'Y'
   
    insert into bHQMA select 'bAPPH', 'Key: ' + convert(char(3), i.CMCo)
    		 + '/' + convert(varchar(4), i.CMAcct)
    		 + '/' + i.PayMethod
    		 + '/' + i.CMRef
    		 + '/' + convert(varchar(1),i.CMRefSeq)
    		 + '/' + convert(varchar(4),i.EFTSeq), i.APCo, 'C',
    	'Address', d.Address, i.Address, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.CMCo = i.CMCo and d.CMAcct = i.CMAcct
        	and d.PayMethod = i.PayMethod and d.CMRef = i.CMRef and d.CMRefSeq = i.CMRefSeq
        	and d.EFTSeq = i.EFTSeq
        join APCO a on a.APCo = i.APCo
    	where d.Address <> i.Address and a.AuditPay = 'Y'
   
    insert into bHQMA select 'bAPPH', 'Key: ' + convert(char(3), i.CMCo)
    		 + '/' + convert(varchar(4), i.CMAcct)
    		 + '/' + i.PayMethod
    		 + '/' + i.CMRef
    		 + '/' + convert(varchar(1),i.CMRefSeq)
    		 + '/' + convert(varchar(4),i.EFTSeq), i.APCo, 'C',
    	'City', d.City, i.City, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.CMCo = i.CMCo and d.CMAcct = i.CMAcct
        	and d.PayMethod = i.PayMethod and d.CMRef = i.CMRef and d.CMRefSeq = i.CMRefSeq
        	and d.EFTSeq = i.EFTSeq
        join APCO a on a.APCo = i.APCo
    	where d.City <> i.City and a.AuditPay = 'Y'
   
    insert into bHQMA select 'bAPPH', 'Key: ' + convert(char(3), i.CMCo)
    		 + '/' + convert(varchar(4), i.CMAcct)
    		 + '/' + i.PayMethod
    		 + '/' + i.CMRef
    		 + '/' + convert(varchar(1),i.CMRefSeq)
    		 + '/' + convert(varchar(4),i.EFTSeq), i.APCo, 'C',
    	'State', d.State, i.State, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.CMCo = i.CMCo and d.CMAcct = i.CMAcct
        	and d.PayMethod = i.PayMethod and d.CMRef = i.CMRef and d.CMRefSeq = i.CMRefSeq
        	and d.EFTSeq = i.EFTSeq
        join APCO a on a.APCo = i.APCo
    	where d.State <> i.State and a.AuditPay = 'Y'
   
    insert into bHQMA select 'bAPPH', 'Key: ' + convert(char(3), i.CMCo)
    		 + '/' + convert(varchar(4), i.CMAcct)
    		 + '/' + i.PayMethod
    		 + '/' + i.CMRef
    		 + '/' + convert(varchar(1),i.CMRefSeq)
    		 + '/' + convert(varchar(4),i.EFTSeq), i.APCo, 'C',
    	'Zip', d.Zip, i.Zip, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.CMCo = i.CMCo and d.CMAcct = i.CMAcct
        	and d.PayMethod = i.PayMethod and d.CMRef = i.CMRef and d.CMRefSeq = i.CMRefSeq
        	and d.EFTSeq = i.EFTSeq
        join APCO a on a.APCo = i.APCo
    	where d.Zip <> i.Zip and a.AuditPay = 'Y'
   
    insert into bHQMA select 'bAPPH', 'Key: ' + convert(char(3), i.CMCo)
    		 + '/' + convert(varchar(4), i.CMAcct)
    		 + '/' + i.PayMethod
    		 + '/' + i.CMRef
    		 + '/' + convert(varchar(1),i.CMRefSeq)
    		 + '/' + convert(varchar(4),i.EFTSeq), i.APCo, 'C',
    	'ChkType', d.ChkType, i.ChkType, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.CMCo = i.CMCo and d.CMAcct = i.CMAcct
        	and d.PayMethod = i.PayMethod and d.CMRef = i.CMRef and d.CMRefSeq = i.CMRefSeq
        	and d.EFTSeq = i.EFTSeq
        join APCO a on a.APCo = i.APCo
    	where d.ChkType <> i.ChkType and a.AuditPay = 'Y'
   
    insert into bHQMA select 'bAPPH', 'Key: ' + convert(char(3), i.CMCo)
    		 + '/' + convert(varchar(4), i.CMAcct)
    		 + '/' + i.PayMethod
    		 + '/' + i.CMRef
    		 + '/' + convert(varchar(1),i.CMRefSeq)
    		 + '/' + convert(varchar(4),i.EFTSeq), i.APCo, 'C',
    	'PaidMth', d.PaidMth, i.PaidMth, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.CMCo = i.CMCo and d.CMAcct = i.CMAcct
        	and d.PayMethod = i.PayMethod and d.CMRef = i.CMRef and d.CMRefSeq = i.CMRefSeq
        	and d.EFTSeq = i.EFTSeq
        join APCO a on a.APCo = i.APCo
    	where d.PaidMth <> i.PaidMth and a.AuditPay = 'Y'
   
   
    insert into bHQMA select 'bAPPH', 'Key: ' + convert(char(3), i.CMCo)
    		 + '/' + convert(varchar(4), i.CMAcct)
    		 + '/' + i.PayMethod
    		 + '/' + i.CMRef
    		 + '/' + convert(varchar(1),i.CMRefSeq)
    		 + '/' + convert(varchar(4),i.EFTSeq), i.APCo, 'C',
    	'PaidDate', d.PaidDate, i.PaidDate, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.CMCo = i.CMCo and d.CMAcct = i.CMAcct
        	and d.PayMethod = i.PayMethod and d.CMRef = i.CMRef and d.CMRefSeq = i.CMRefSeq
        	and d.EFTSeq = i.EFTSeq
        join APCO a on a.APCo = i.APCo
    	where d.PaidDate <> i.PaidDate and a.AuditPay = 'Y'
   
    insert into bHQMA select 'bAPPH', 'Key: ' + convert(char(3), i.CMCo)
    		 + '/' + convert(varchar(4), i.CMAcct)
    		 + '/' + i.PayMethod
    		 + '/' + i.CMRef
   
    		 + '/' + convert(varchar(1),i.CMRefSeq)
    		 + '/' + convert(varchar(4),i.EFTSeq), i.APCo, 'C',
    	'Amount', convert(varchar(16),d.Amount), convert(varchar(16),i.Amount), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.CMCo = i.CMCo and d.CMAcct = i.CMAcct
        	and d.PayMethod = i.PayMethod and d.CMRef = i.CMRef and d.CMRefSeq = i.CMRefSeq
        	and d.EFTSeq = i.EFTSeq
        join APCO a on a.APCo = i.APCo
    	where d.Amount <> i.Amount and a.AuditPay = 'Y'
   
    insert into bHQMA select 'bAPPH', 'Key: ' + convert(char(3), i.CMCo)
    		 + '/' + convert(varchar(4), i.CMAcct)
    		 + '/' + i.PayMethod
    		 + '/' + i.CMRef
    		 + '/' + convert(varchar(1),i.CMRefSeq)
    		 + '/' + convert(varchar(4),i.EFTSeq), i.APCo, 'C',
    	'Supplier', convert(varchar(6),d.Supplier), convert(varchar(6),i.Supplier), getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.CMCo = i.CMCo and d.CMAcct = i.CMAcct
        	and d.PayMethod = i.PayMethod and d.CMRef = i.CMRef and d.CMRefSeq = i.CMRefSeq
        	and d.EFTSeq = i.EFTSeq
        join APCO a on a.APCo = i.APCo
    	where d.Supplier <> i.Supplier and a.AuditPay = 'Y'
   
   
    insert into bHQMA select 'bAPPH', 'Key: ' + convert(char(3), i.CMCo)
    		 + '/' + convert(varchar(4), i.CMAcct)
    		 + '/' + i.PayMethod
    		 + '/' + i.CMRef
    		 + '/' + convert(varchar(1),i.CMRefSeq)
    		 + '/' + convert(varchar(4),i.EFTSeq), i.APCo, 'C',
    	'VoidYN', d.VoidYN, i.VoidYN, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.CMCo = i.CMCo and d.CMAcct = i.CMAcct
        	and d.PayMethod = i.PayMethod and d.CMRef = i.CMRef and d.CMRefSeq = i.CMRefSeq
        	and d.EFTSeq = i.EFTSeq
        join APCO a on a.APCo = i.APCo
    	where d.VoidYN <> i.VoidYN and a.AuditPay = 'Y'
   
    insert into bHQMA select 'bAPPH', 'Key: ' + convert(char(3), i.CMCo)
    		 + '/' + convert(varchar(4), i.CMAcct)
    		 + '/' + i.PayMethod
    		 + '/' + i.CMRef
    		 + '/' + convert(varchar(1),i.CMRefSeq)
    		 + '/' + convert(varchar(4),i.EFTSeq), i.APCo, 'C',
    	'VoidMemo', d.VoidMemo, i.VoidMemo, getdate(), SUSER_SNAME()
    	from inserted i
        join deleted d on d.APCo = i.APCo and d.CMCo = i.CMCo and d.CMAcct = i.CMAcct
        	and d.PayMethod = i.PayMethod and d.CMRef = i.CMRef and d.CMRefSeq = i.CMRefSeq
        	and d.EFTSeq = i.EFTSeq
        join APCO a on a.APCo = i.APCo
    	where d.VoidMemo <> i.VoidMemo and a.AuditPay = 'Y'
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot update AP Payment Header!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
  
 



GO
ALTER TABLE [dbo].[bAPPH] WITH NOCHECK ADD CONSTRAINT [CK_bAPPH_CMAcct] CHECK (([CMAcct]>(0) AND [CMAcct]<(10000)))
GO
ALTER TABLE [dbo].[bAPPH] WITH NOCHECK ADD CONSTRAINT [CK_bAPPH_PurgeYN] CHECK (([PurgeYN]='Y' OR [PurgeYN]='N'))
GO
ALTER TABLE [dbo].[bAPPH] WITH NOCHECK ADD CONSTRAINT [CK_bAPPH_VoidYN] CHECK (([VoidYN]='Y' OR [VoidYN]='N'))
GO
CREATE UNIQUE CLUSTERED INDEX [biAPPH] ON [dbo].[bAPPH] ([APCo], [CMCo], [CMAcct], [PayMethod], [CMRef], [CMRefSeq], [EFTSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biAPPHCMRef] ON [dbo].[bAPPH] ([CMRef]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bAPPH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
